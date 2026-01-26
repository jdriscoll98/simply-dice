import { FirebaseAnalytics } from '@capacitor-firebase/analytics';
import { Capacitor } from '@capacitor/core';

export const initAnalytics = async () => {
    try {
        if (Capacitor.isNativePlatform()) {
            await FirebaseAnalytics.setEnabled({
                enabled: true,
            });
        }
        console.log('Firebase Analytics initialized');
    } catch (e) {
        console.error('Firebase Analytics init failed', e);
    }
};

const logEvent = async (name: string, params: any = {}) => {
    try {
        if (Capacitor.isNativePlatform()) {
            console.log(`[Analytics] ${name}`, params);
            await FirebaseAnalytics.logEvent({
                name,
                params,
            });
        } else {
            console.log(`[Analytics] ${name}`, params);
        }
    } catch (e) {
        console.warn(`[Analytics] Failed to log ${name}`, e);
    }
};

export const logRollDice = () => {
    logEvent('roll_dice');
};

export const logOpenSettings = () => {
    logEvent('open_settings');
};

export const logChangeSettings = (setting: string, value: boolean) => {
    logEvent('change_settings', {
        setting_name: setting,
        new_value: value ? 'on' : 'off'
    });
};

export const logShareApp = () => {
    logEvent('share_app');
};
