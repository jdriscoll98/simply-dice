<template>
    <ion-page>
        <ion-content :fullscreen="true" :scrollY="false" class="dice-content">

            <div class="brand-cue">Simply Dice</div>

            <ion-button fill="clear" class="settings-chip" @click="openSettings">
                <ion-icon slot="icon-only" :icon="settingsOutline"></ion-icon>
            </ion-button>

            <div class="scene-wrapper" @click="handleRoll">
                <ThreeDice ref="diceComponent" @roll-complete="onRollComplete" />
            </div>

            <div class="instructions" :class="{ 'faded': isRolling }">
                {{ instructionText }}
            </div>

            <SettingsModal v-model:is-open="isSettingsOpen" v-model:sound="soundEnabled" v-model:haptics="hapticEnabled" v-model:shake="shakeEnabled" :version="appVersion" />
        </ion-content>
    </ion-page>
</template>

<script setup lang="ts">
import {
    IonContent,
    IonPage,
    IonButton,
    IonIcon
} from '@ionic/vue';
import { settingsOutline } from 'ionicons/icons';
import { ref, computed } from 'vue';
import ThreeDice from '@/components/ThreeDice.vue';
import SettingsModal from '@/components/SettingsModal.vue';
import { logRollDice, logOpenSettings } from '@/services/analytics';

const diceComponent = ref<InstanceType<typeof ThreeDice> | null>(null);

const isSettingsOpen = ref(false);
const isRolling = ref(false);
const soundEnabled = ref(true);
const hapticEnabled = ref(true);

let currentAudio: HTMLAudioElement | null = null;
let fadeInterval: any = null;

const playRollSound = () => {
    if (!soundEnabled.value) return;

    // Cleanup previous audio and fade if any
    if (currentAudio) {
        currentAudio.pause();
        currentAudio = null;
    }
    if (fadeInterval) {
        clearInterval(fadeInterval);
        fadeInterval = null;
    }

    // Create fresh instance for reliability
    const audio = new Audio('/sounds/dice_roll.mp3');
    currentAudio = audio;

    audio.play().catch(e => {
        console.warn("Audio play failed:", e);
    });
};

const handleRoll = () => {
    if (!isSettingsOpen.value && !isRolling.value) {
        // Only play if the dice component actually starts a roll
        // We cast to any because TS might not infer the return type change immediately without full reload
        if ((diceComponent.value as any)?.roll()) {
            isRolling.value = true;
            playRollSound();
            triggerHaptic(ImpactStyle.Light);
            logRollDice();
        }
    }
};

const openSettings = () => {
    isSettingsOpen.value = true;
    logOpenSettings();
};

const onRollComplete = () => {
    isRolling.value = false;
    triggerHaptic(ImpactStyle.Medium);

    if (!currentAudio || currentAudio.paused) return;

    const audioToFade = currentAudio; // Capture reference

    // Clear any previous interval
    if (fadeInterval) clearInterval(fadeInterval);

    fadeInterval = setInterval(() => {
        if (audioToFade.volume > 0.1) {
            audioToFade.volume = Math.max(0, audioToFade.volume - 0.1);
        } else {
            audioToFade.pause();
            if (currentAudio === audioToFade) {
                // Audio finished fading
            }
            clearInterval(fadeInterval);
            fadeInterval = null;
        }
    }, 50);
};

import { onMounted, onUnmounted, watch } from 'vue';
import { Haptics, ImpactStyle } from '@capacitor/haptics';
import { CapacitorShake } from '@capgo/capacitor-shake';
import { App } from '@capacitor/app';
import { Preferences } from '@capacitor/preferences';

const shakeEnabled = ref(false);
let shakeListener: any = null;
const appVersion = ref('1.0.0');

// Settings Keys
const SETTINGS_KEY = 'simply_dice_settings';

const loadSettings = async () => {
    try {
        const { value } = await Preferences.get({ key: SETTINGS_KEY });
        if (value) {
            const settings = JSON.parse(value);
            if (settings.sound !== undefined) soundEnabled.value = settings.sound;
            if (settings.haptics !== undefined) hapticEnabled.value = settings.haptics;
            if (settings.shake !== undefined) shakeEnabled.value = settings.shake;
        }
    } catch (e) {
        console.warn('Error loading settings', e);
    }
};

const saveSettings = async () => {
    try {
        const settings = {
            sound: soundEnabled.value,
            haptics: hapticEnabled.value,
            shake: shakeEnabled.value
        };
        await Preferences.set({
            key: SETTINGS_KEY,
            value: JSON.stringify(settings)
        });
    } catch (e) {
        console.warn('Error saving settings', e);
    }
};


const instructionText = computed(() => {
    return shakeEnabled.value ? 'Tap or shake to roll' : 'Tap anywhere to roll';
});

onMounted(async () => {
    await loadSettings();
    try {
        const info = await App.getInfo();
        appVersion.value = `${info.version} (${info.build})`;
    } catch (e) {
        // Fallback for web
        console.debug('App info not available', e);
    }

    App.addListener('appStateChange', ({ isActive }) => {
        if (!isActive) {
            saveSettings();
        }
    });
});


const startShakeListener = async () => {
    if (shakeListener) return;
    try {
        shakeListener = await CapacitorShake.addListener('shake', () => {
            handleRoll();
        });
    } catch (e) {
        console.warn('Shake listener failed', e);
    }
};

const stopShakeListener = async () => {
    try {
        if (shakeListener) {
            await shakeListener.remove();
            shakeListener = null;
        }
    } catch { /* ignore */ }
};

watch(shakeEnabled, (enabled) => {
    if (enabled) {
        startShakeListener();
    } else {
        stopShakeListener();
    }
    saveSettings();
});

watch([soundEnabled, hapticEnabled], () => {
    saveSettings();
});

const triggerHaptic = async (style: ImpactStyle) => {
    if (!hapticEnabled.value) return;
    try {
        await Haptics.impact({ style });
    } catch (e) {
        console.warn('Haptics failed', e);
    }
};



onUnmounted(() => {
    stopShakeListener();
});
</script>

<style scoped>
.dice-content {
    --background: #000;
    /* Vignette centered slightly higher (50% 40%) to match dice position */
    background: radial-gradient(circle at 50% 40%, #080808 0%, #000000 80%);
    contain: size style;
    overscroll-behavior-y: none;
}

.brand-cue {
    position: absolute;
    /* Consistent top alignment with settings chip */
    top: max(var(--ion-safe-area-top), 16px);
    height: 44px;
    /* Match chip height for vertical centering */
    display: flex;
    align-items: center;
    left: 24px;

    color: #fff;
    font-size: 18px;
    font-weight: 600;
    letter-spacing: -0.3px;
    opacity: 0.22;
    z-index: 20;
    pointer-events: none;
}

.settings-chip {
    position: absolute;
    top: max(var(--ion-safe-area-top), 14px);
    right: 16px;
    z-index: 30;

    /* True Circular Glass Chip */
    --background: rgba(255, 255, 255, 0.1);
    --background-activated: rgba(255, 255, 255, 0.15);
    --border-radius: 50%;
    --color: rgba(255, 255, 255, 0.9);
    --padding-start: 0;
    --padding-end: 0;

    width: 44px;
    height: 44px;

    /* Ensure no square artifact */
    border-radius: 50%;
    overflow: hidden;

    backdrop-filter: blur(6px);
    -webkit-backdrop-filter: blur(6px);

    border: 0.5px solid rgba(255, 255, 255, 0.12);
}

.settings-chip ion-icon {
    font-size: 20px;
}

.scene-wrapper {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    z-index: 10;
}

.instructions {
    position: absolute;
    bottom: 50px;
    width: 100%;
    text-align: center;
    color: #fff;
    font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif;
    font-weight: 500;
    letter-spacing: 0.4px;
    font-size: 13px;

    /* Base state: visible but subtle */
    opacity: 0.55;

    pointer-events: none;
    user-select: none;
    z-index: 20;

    /* Consistent transition for fade in/out */
    transition: opacity 0.3s ease;
}

.instructions.faded {
    /* Slight fade during roll, still readable */
    opacity: 0.3;
}
</style>
