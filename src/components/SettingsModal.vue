<template>
    <ion-modal ref="modal" :is-open="isOpen" class="settings-sheet" @didDismiss="handleDismiss" :initial-breakpoint="1" :breakpoints="[0, 1]">
        <div class="sheet-container">


            <!-- Header -->
            <div class="sheet-header">
                <div class="header-top">
                    <div class="brand-group">
                        <div class="brand-icon">
                            <div class="mini-die">
                                <span class="pip"></span>
                                <span class="pip"></span>
                            </div>
                        </div>
                        <span class="brand-title">Simply Dice</span>
                    </div>
                    <button class="done-btn" @click.stop.prevent="handleDone">Done</button>
                </div>
                <div class="header-subtitle">Roll preferences</div>
            </div>

            <!-- Controls Card -->
            <div class="controls-card">
                <!-- Sound -->
                <div class="control-row">
                    <div class="icon-box">
                        <Icon icon="mdi:volume-high" />
                    </div>
                    <div class="text-stack">
                        <div class="row-title">Sound</div>
                        <div class="row-subtitle">Play roll effects</div>
                    </div>
                    <DiceToggle :model-value="sound" @update:model-value="updateSetting('sound', $event)" />
                </div>

                <div class="divider"></div>

                <!-- Haptics -->
                <div class="control-row">
                    <div class="icon-box">
                        <Icon icon="ph:vibrate-fill" />
                    </div>
                    <div class="text-stack">
                        <div class="row-title">Haptics</div>
                        <div class="row-subtitle">Vibrate on impact</div>
                    </div>
                    <DiceToggle :model-value="haptics" @update:model-value="updateSetting('haptics', $event)" />
                </div>

                <div class="divider"></div>

                <!-- Shake to Roll -->
                <div class="control-row">
                    <div class="icon-box">
                        <Icon icon="icon-park-solid:screen-rotation" />
                    </div>
                    <div class="text-stack">
                        <div class="row-title">Shake</div>
                        <div class="row-subtitle">Shake device to roll</div>
                    </div>
                    <DiceToggle :model-value="shake" @update:model-value="updateSetting('shake', $event)" />
                </div>
            </div>

            <!-- Share Button -->
            <div class="action-card" @click="shareApp">
                <div class="action-content">
                    <div class="text-stack">
                        <div class="row-title">Share App</div>
                        <div class="row-subtitle">Send to a friend</div>
                    </div>
                    <div class="share-chip">
                        <Icon icon="ion:share" />
                    </div>
                </div>
            </div>

            <!-- About -->
            <div class="about-section">
                <div class="about-brand">Simply Dice</div>
                <div class="version-text">Version {{ version }}</div>
                <div class="made-with">Made with ❤️ in Gainesville, FL</div>
            </div>
        </div>
    </ion-modal>
</template>

<script setup lang="ts">

import { IonModal } from '@ionic/vue';
import { Icon } from '@iconify/vue';
import { Share } from '@capacitor/share';
import DiceToggle from '@/components/ui/DiceToggle.vue';
import { logChangeSettings, logShareApp } from '@/services/analytics';
import { ref } from 'vue';

defineProps<{
    isOpen: boolean;
    sound: boolean;
    haptics: boolean;
    shake: boolean;
    version: string;
}>();

const emit = defineEmits<{
    (e: 'update:isOpen', value: boolean): void;
    (e: 'update:sound', value: boolean): void;
    (e: 'update:haptics', value: boolean): void;
    (e: 'update:shake', value: boolean): void;
}>();

const modal = ref<null | any>(null);

const handleDismiss = () => {
    emit('update:isOpen', false);
};

const handleDone = async () => {
    // Dismissing programmatically ensures the modal handles the state change via didDismiss
    // This keeps isOpen true during the animation, blocking the background
    if (modal.value) {
        await modal.value.$el.dismiss();
    }
};

const updateSetting = (setting: 'sound' | 'haptics' | 'shake', value: boolean) => {
    logChangeSettings(setting, value);
    (emit as any)(`update:${setting}`, value);
};

const shareApp = async () => {
    logShareApp();
    const shareData = {
        title: 'Simply Dice: Roll Anywhere',
        text: 'Check out Simply Dice!',
        url: 'https://apps.apple.com/us/app/simply-dice-roll-anywhere/id6759136034'
    };
    try {
        await Share.share(shareData);
    } catch (e) {
        console.warn('Share failed', e);
    }
};
</script>

<style scoped>
/* Modal CSS is tricky because it hits the shadow DOM. 
   We usually target the class via global styles or ::part. 
   However, scoped styles won't reach ion-modal structure unless we use ::part or put the class on the modal and use global css.
   But we can style the content inside our div easily.
*/

.sheet-container {
    height: 100%;
    background-color: #050505;
    /* Deep black/dark */
    background: radial-gradient(circle at center, #1a1a1e 0%, #000000 100%);
    display: flex;
    flex-direction: column;
    padding: 24px 20px;
    padding-top: 24px;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    color: white;
    overflow-y: auto;
    -webkit-overflow-scrolling: touch;
}

/* Header */
.sheet-header {
    margin-bottom: 32px;
}

.header-top {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 8px;
}

.brand-group {
    display: flex;
    align-items: center;
    gap: 12px;
}



.mini-die {
    width: 28px;
    height: 28px;
    background: white;
    border-radius: 6px;
    display: flex;
    justify-content: space-between;
    padding: 4px;
    box-shadow: 0 2px 8px rgba(255, 255, 255, 0.1);
}

.pip {
    width: 6px;
    height: 6px;
    background: black;
    border-radius: 50%;
}

.mini-die .pip:nth-child(2) {
    align-self: flex-end;
}

.brand-title {
    font-size: 22px;
    font-weight: 700;
    letter-spacing: -0.5px;
    background: linear-gradient(to right, #fff, #bbb);
    -webkit-background-clip: text;
    background-clip: text;
    -webkit-text-fill-color: transparent;
}

.header-subtitle {
    font-size: 14px;
    color: #666;
    margin-left: 4px;
    /* Align slightly with text */
    font-weight: 500;
}

/* Done Button */
.done-btn {
    background: #111;
    border: 1px solid rgba(255, 255, 255, 0.12);
    color: rgba(255, 255, 255, 0.9);
    padding: 8px 20px;
    border-radius: 20px;
    font-size: 14px;
    font-weight: 600;
    transition: all 0.2s ease;
    box-shadow: 0 0 10px rgba(255, 255, 255, 0.02);
}

.done-btn:active {
    transform: scale(0.96);
    background: #1a1a1a;
}

/* Cards */
.controls-card,
.action-card {
    background: #0B0B0D;
    background-color: #101013;
    border: 1px solid rgba(255, 255, 255, 0.08);
    /* 8-12% opacity */
    border-radius: 24px;
    padding: 8px 0;
    margin-bottom: 16px;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.4);
}

.action-card {
    padding: 16px 20px;
    cursor: pointer;
    transition: all 0.2s ease;
}

.action-card:active {
    background: #161619;
    transform: scale(0.98);
}

.action-content {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

/* Rows */
.control-row {
    padding: 16px 20px;
    display: flex;
    align-items: center;
    min-height: 64px;
}

.divider {
    height: 1px;
    background: rgba(255, 255, 255, 0.06);
    /* Very faint */
    margin: 0 20px;
}

.icon-box {
    width: 32px;
    height: 32px;
    background: rgba(255, 255, 255, 0.08);
    border-radius: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-right: 16px;
    color: #ddd;
    font-size: 18px;
}

.text-stack {
    flex: 1;
    display: flex;
    flex-direction: column;
    justify-content: center;
}

.row-title {
    font-weight: 600;
    font-size: 16px;
    color: #eee;
    margin-bottom: 2px;
}

.row-subtitle {
    font-size: 12px;
    color: #666;
}



/* Share Chip */
.share-chip {
    background: rgba(255, 255, 255, 0.1);
    width: 36px;
    height: 36px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
}

/* About */
.about-section {
    margin-top: auto;
    text-align: center;
    padding: 40px 0 20px;
    opacity: 0.8;
}

.about-brand {
    font-size: 14px;
    font-weight: 700;
    color: #fff;
    margin-bottom: 4px;
}

.version-text {
    font-size: 12px;
    color: #555;
}

.made-with {
    font-size: 10px;
    color: #444;
    margin-top: 8px;
}
</style>

<style>
/* Global overrides for the specific modal */
ion-modal.settings-sheet {
    --border-radius: 32px 32px 0 0;
    --height: calc(100% - var(--ion-safe-area-top));
    align-items: flex-end;
    --background: transparent;
    /* We control background in sheet-container */
    --backdrop-opacity: 0;
    /* Transparent backdrop but blocks interaction */
}
</style>
