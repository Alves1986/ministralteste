
// Serviço Vagalume/CifraClub via REST direto.
// O pacote 'vagalume@1.0.3' está QUEBRADO em runtime moderno (Node ESM):
//   - imports sem extensão (core-js/library/es6/promise) falham no resolver ESM
//   - "Vagalume is not a constructor" ao instanciar (verificado em teste de fluxo)
// Chamadas diretas à API pública do Vagalume funcionam sem apikey (mesmos endpoints
// que o pacote usava internamente).

export interface CifraClubResult {
    title: string;
    artist: string;
    url: string;
    key: string;
}

// Cache simples para evitar chamadas repetitivas
const searchCache: Record<string, CifraClubResult[]> = {};

const VAGALUME_API = 'https://api.vagalume.com.br';
const WEB_BASE = 'https://www.vagalume.com.br';

const HEADERS = { 'User-Agent': 'Ministral/1.0 (gestao de ministerios)' };

export const searchCifraClub = async (query: string): Promise<CifraClubResult[]> => {
    if (typeof window !== 'undefined') {
        try {
            const res = await fetch('/api/cifraclub/search', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ query })
            });
            if (!res.ok) {
                const errData = await res.json().catch(() => ({}));
                throw new Error(errData.error || 'Erro na API do Vagalume Proxy');
            }
            return await res.json();
        } catch (error: any) {
            console.error("Error calling Vagalume API proxy", error);
            return [];
        }
    }

    const cacheKey = query.toLowerCase().trim();
    if (searchCache[cacheKey]) {
        return searchCache[cacheKey];
    }

    try {
        const res = await fetch(
            `${VAGALUME_API}/search.artmus?q=${encodeURIComponent(query)}&limit=10`,
            { headers: HEADERS }
        );
        if (!res.ok) {
            console.error(`Vagalume Search HTTP ${res.status}`);
            return [];
        }
        const data = await res.json();

        if (data && data.response && data.response.docs) {
            const results: CifraClubResult[] = data.response.docs.map((doc: any) => ({
                title: doc.title || "Unknown",
                artist: doc.band || doc.artist || "Unknown",
                url: doc.url ? `${WEB_BASE}${doc.url}` : `${WEB_BASE}/`,
                key: "-"
            }));

            searchCache[cacheKey] = results;
            return results;
        }
        return [];
    } catch (e) {
        console.error("Vagalume Search Error:", e);
        return [];
    }
};

export const getVagalumeLyrics = async (artist: string, song: string, url?: string): Promise<string> => {
    if (typeof window !== 'undefined') {
        try {
            const res = await fetch('/api/cifraclub/lyrics', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ artist, song, url })
            });
            if (!res.ok) {
                return "";
            }
            const data = await res.json();
            return data.lyrics || "";
        } catch (error: any) {
            console.error("Error calling Vagalume Lyrics proxy", error);
            return "";
        }
    }

    try {
        if (url && url !== `${WEB_BASE}/`) {
            try {
                const htmlRes = await fetch(url, { headers: HEADERS });
                const html = await htmlRes.text();
                // Extract from <div id="lyrics"> ... </div>
                const match = html.match(/<div id="lyrics">([\s\S]*?)<\/div>/i);
                if (match && match[1]) {
                    // Convert <br/> to \n and remove other tags
                    return match[1].replace(/<br\s*\/?>/gi, '\n').replace(/<\/?[^>]+(>|$)/g, '').trim();
                }
            } catch (err) {
                console.error("Vagalume HTML Fetch Error:", err);
            }
        }

        const res = await fetch(
            `${VAGALUME_API}/search.php?art=${encodeURIComponent(artist)}&mus=${encodeURIComponent(song)}`,
            { headers: HEADERS }
        );
        if (!res.ok) return "";
        const data = await res.json();

        if (data && (data.type === 'exact' || data.type === 'aprox') && data.mus && data.mus.length > 0) {
            return data.mus[0].text || "";
        }

        return "";
    } catch (e) {
        console.error("Vagalume Lyrics Fetch Error:", e);
        return "";
    }
};
