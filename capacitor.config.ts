import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'br.com.ministral.app',
  appName: 'Ministral',
  webDir: 'dist',
  // https://localhost permite service worker no WebView do Android
  server: {
    androidScheme: 'https'
  }
};

export default config;
