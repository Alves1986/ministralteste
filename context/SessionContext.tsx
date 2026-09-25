import React, { createContext, useContext, useEffect, useState, useRef, ReactNode } from 'react';
import { 
    fetchUserAllowedMinistries, 
    fetchUserMinistryAccess,
    fetchOrganizationDetails
} from '../services/supabaseService';
import { getSupabase, setServiceOrgContext, clearServiceOrgContext } from '../services/supabase/client';
import { useAppStore } from '../store/appStore';
import { User, Organization } from '../types';

type SessionStatus = 
    | 'idle' 
    | 'authenticating' 
    | 'contextualizing' 
    | 'ready' 
    | 'unauthenticated' 
    | 'error'
    | 'locked_inactive'
    | 'locked_billing';

interface SessionContextValue {
    status: SessionStatus;
    user: User | null;
    error: Error | null;
    organization: Organization | null;
    refreshSession: () => Promise<void>;
}

const SessionContext = createContext<SessionContextValue | undefined>(undefined);

export const useSession = () => {
    const context = useContext(SessionContext);
    if (!context) {
        throw new Error('useSession must be used within a SessionProvider');
    }
    return context;
};

interface SessionProviderProps {
    children: ReactNode;
}

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export const SessionProvider: React.FC<SessionProviderProps> = ({ children }) => {
    const [status, setStatus] = useState<SessionStatus>('idle');
    const [user, setUser] = useState<User | null>(null);
    const [organization, setOrganization] = useState<Organization | null>(null);
    const [error, setError] = useState<Error | null>(null);
    
    const userRef = useRef<User | null>(null);
    const isProcessingRef = useRef(false);
    const activeChannelRef = useRef<any>(null);
    const isMountedRef = useRef(false);

    useEffect(() => {
        isMountedRef.current = true;
        return () => { isMountedRef.current = false; };
    }, []);

    const processSession = React.useCallback(async (sessionUser: any) => {
        if (!isMountedRef.current) return;
        if (isProcessingRef.current) return;

        const sb = getSupabase();
        if (!sb) return;

        const isSameUser = userRef.current?.id === sessionUser.id;
        if (!isSameUser) {
            setStatus('contextualizing');
        }

        let channel: any = null;

        try {
            isProcessingRef.current = true;
            
            if (activeChannelRef.current) {
                activeChannelRef.current.unsubscribe();
                activeChannelRef.current = null;
            }

            channel = sb.channel(`profile-sync-${sessionUser.id}`)
                .on('postgres_changes', { event: '*', schema: 'public', table: 'profiles', filter: `id=eq.${sessionUser.id}` }, 
                (payload: any) => {
                    if (userRef.current?.isSuperAdmin && !userRef.current?.organizationId) return;
                    if (payload.new && payload.new.organization_id) {
                        isProcessingRef.current = false;
                        processSession(sessionUser);
                    }
                })
                .subscribe();
            
            activeChannelRef.current = channel;

            const { data: profile, error: profileError } = await sb
                .from('profiles')
                .select('*')
                .eq('id', sessionUser.id)
                .maybeSingle();
            
            if (profileError) throw profileError;

            if (!profile) {
                console.warn("[SessionProvider] No profile found for user");
                isProcessingRef.current = false;
                setTimeout(() => {
                    if (isMountedRef.current && !userRef.current) {
                        setUser(null);
                        setStatus('unauthenticated');
                        if (channel) channel.unsubscribe();
                    }
                }, 10000);
                return;
            }

            const orgId = profile.organization_id || '';

            if (profile.is_super_admin || profile.is_admin) {
                if (activeChannelRef.current) {
                    activeChannelRef.current.unsubscribe();
                    activeChannelRef.current = null;
                }
                
                // Para Admins, buscamos os ministérios e a função do ministério ativo para liberar o menu
                const [ministries, guessedAccess] = await Promise.all([
                    fetchUserAllowedMinistries(profile.id, orgId),
                    guessedMinistry ? fetchUserMinistryAccess(profile.id, guessedMinistry, orgId).catch(() => null) : Promise.resolve(null)
                ]);

                const adminObj = {
                    id: profile.id,
                    name: profile.name || 'Administrador',
                    email: profile.email || sessionUser.email,
                    access_role: 'admin',
                    isSuperAdmin: !!profile.is_super_admin,
                    isOrgAdmin: !!profile.is_admin,
                    isPro: true,
                    isEnterprise: true,
                    organizationId: orgId,
                    ministryId: guessedMinistry || (ministries.length > 0 ? ministries[0] : ''),
                    allowedMinistries: ministries,
                    ministry_functions: guessedAccess?.functions || [],
                    avatar_url: profile.avatar_url,
                    whatsapp: profile.whatsapp,
                    birthDate: profile.birth_date,
                };

                if (isMountedRef.current) {
                    setUser(adminObj as User);
                    setOrganization(orgDetails);
                    setStatus('ready');
                }
                isProcessingRef.current = false;
                return;
            }

            if (!orgId) {
                isProcessingRef.current = false;
                const hasPendingInvite = localStorage.getItem('pending_invite_token');
                if (hasPendingInvite) {
                    setTimeout(async () => {
                        if (!isMountedRef.current) return;
                        const { data: freshProfile } = await sb.from('profiles').select('organization_id').eq('id', sessionUser.id).maybeSingle();
                        if (!freshProfile?.organization_id && isMountedRef.current) {
                            setStatus('error');
                            setError(new Error("Não foi possível vincular sua conta a uma organização."));
                        }
                    }, 30000);
                    return;
                }
                sb.auth.signOut().catch(console.error);
                if (isMountedRef.current) {
                    setUser(null);
                    setStatus('unauthenticated');
                }
                if (channel) channel.unsubscribe();
                return;
            }

            if (orgId && activeChannelRef.current) {
                activeChannelRef.current.unsubscribe();
                channel = sb.channel(`sync-org-profile-${sessionUser.id}`)
                    .on('postgres_changes', { event: '*', schema: 'public', table: 'profiles', filter: `id=eq.${sessionUser.id}` }, () => {
                        isProcessingRef.current = false;
                        processSession(sessionUser);
                    })
                    .on('postgres_changes', { event: '*', schema: 'public', table: 'organizations', filter: `id=eq.${orgId}` }, () => {
                        isProcessingRef.current = false;
                        processSession(sessionUser);
                    })
                    .subscribe();
                activeChannelRef.current = channel;
            }

            setServiceOrgContext(orgId);
            const [details, ministries] = await Promise.all([
                fetchOrganizationDetails(orgId),
                fetchUserAllowedMinistries(profile.id, orgId)
            ]);
            
            setOrganization(details);

            if (details?.active === false) {
                if (isMountedRef.current) {
                    setUser({ id: profile.id, name: profile.name, email: profile.email, access_role: 'member', organizationId: orgId } as User);
                    setStatus('locked_inactive');
                }
                isProcessingRef.current = false;
                return;
            }

            let activeMinistry = '';
            let ministry_functions = [];
            let ministry_role = 'member';

            try {
                const currentMinistryId = useAppStore.getState().ministryId;
                if (currentMinistryId && ministries.includes(currentMinistryId)) {
                    activeMinistry = currentMinistryId;
                } else if (profile.ministry_id && ministries.includes(profile.ministry_id)) {
                    activeMinistry = profile.ministry_id;
                } else if (ministries.length > 0) {
                    activeMinistry = ministries[0];
                }

                if (activeMinistry) {
                    const access = await fetchUserMinistryAccess(profile.id, activeMinistry, orgId);
                    ministry_functions = access.functions || [];
                    ministry_role = access.role || 'member';
                }
            } catch (e) {
                console.error("Ministry access error:", e);
            }

            const authenticatedUser: User = {
                id: profile.id,
                name: profile.name || 'Usuário',
                email: profile.email || sessionUser.email,
                access_role: (profile.is_admin || profile.is_super_admin) ? 'admin' : (ministry_role === 'admin' ? 'admin' : 'member'),
                ministryId: activeMinistry,
                allowedMinistries: ministries,
                organizationId: orgId,
                isSuperAdmin: !!profile.is_super_admin,
                isOrgAdmin: !!profile.is_admin,
                isPro: details?.plan_type === 'pro' || details?.plan_type === 'enterprise',
                isEnterprise: details?.plan_type === 'enterprise',
                avatar_url: profile.avatar_url,
                whatsapp: profile.whatsapp,
                birthDate: profile.birth_date,
                ministry_functions
            };

            if (isMountedRef.current) {
                setUser(authenticatedUser);
                setStatus('ready');
            }
            isProcessingRef.current = false;

        } catch (err: any) {
            isProcessingRef.current = false;
            if (isMountedRef.current) {
                if (isSameUser) {
                    setStatus('ready');
                } else {
                    setError(err);
                    setStatus('error');
                }
            }
        }
    }, []);

    const refreshSession = async () => {
        const sb = getSupabase();
        const session = await sb?.auth.getSession();
        const sessionUser = session?.data.session?.user;
        if (!sessionUser) return;
        await processSession(sessionUser);
    };

    useEffect(() => {
        userRef.current = user;
    }, [user]);

    useEffect(() => {
        const sb = getSupabase();
        if (!sb) {
            setStatus('unauthenticated');
            return;
        }

        const init = async () => {
            if (!isMountedRef.current) return;
            if (!userRef.current) setStatus('authenticating');
            
            try {
                const { data: { session } } = await sb.auth.getSession();
                if (session?.user) {
                    await processSession(session.user);
                } else {
                    if (isMountedRef.current) {
                        setUser(null);
                        setStatus('unauthenticated');
                    }
                }
            } catch (e: any) {
                if (isMountedRef.current) {
                    setError(e);
                    setStatus('error');
                }
                return;
            }

            const { data: { subscription } } = sb.auth.onAuthStateChange(async (event, currentSession) => {
                if (!isMountedRef.current) return;
                if (event === 'SIGNED_IN' && currentSession?.user) {
                    const isSameUser = userRef.current?.id === currentSession.user.id;
                    if (!isSameUser || userRef.current === null) {
                        await processSession(currentSession.user);
                    }
                } else if (event === 'SIGNED_OUT') {
                    setUser(null);
                    setStatus('unauthenticated');
                    clearServiceOrgContext();
                }
            });
            return subscription;
        };

        let authSubscription: any = null;
        init().then(sub => {
            authSubscription = sub;
            if (!isMountedRef.current && authSubscription) {
                authSubscription.unsubscribe();
            }
        });

        return () => {
            if (authSubscription) authSubscription.unsubscribe();
            if (activeChannelRef.current) activeChannelRef.current.unsubscribe();
        };
    }, [processSession]);

    const contextValue: SessionContextValue = { status, user, error, organization, refreshSession };
    return <SessionContext.Provider value={contextValue}>{children}</SessionContext.Provider>;
};
