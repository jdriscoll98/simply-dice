<template>
  <div class="dice-toggle" :class="{ 'is-active': modelValue }" @click="toggle">
    <div class="toggle-track"></div>
    <div class="toggle-pip">
      <div class="pip-dot" v-if="modelValue"></div>
    </div>
  </div>
</template>

<script setup lang="ts">

import { Haptics, ImpactStyle } from '@capacitor/haptics';

const props = defineProps<{
  modelValue: boolean;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void;
}>();

const toggle = async () => {
  const newValue = !props.modelValue;
  emit('update:modelValue', newValue);

  try {
    await Haptics.impact({ style: ImpactStyle.Light });
  } catch {
    // Ignore haptics error on web
  }
};
</script>

<style scoped>
.dice-toggle {
  position: relative;
  width: 52px;
  height: 32px;
  cursor: pointer;
  -webkit-tap-highlight-color: transparent;
}

.toggle-track {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  border-radius: 16px;
  background-color: #333;
  /* Dark gray when off */
  transition: background-color 0.3s ease;
}

.is-active .toggle-track {
  background-color: #4a4a4a;
  /* Muted graphite gradient base */
  background: linear-gradient(135deg, #444, #555);
}

.toggle-pip {
  position: absolute;
  top: 2px;
  left: 2px;
  width: 28px;
  height: 28px;
  background-color: white;
  border-radius: 50%;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
  transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
  /* Bouncy spring */
  display: flex;
  align-items: center;
  justify-content: center;
}

.is-active .toggle-pip {
  transform: translateX(20px);
}

.pip-dot {
  width: 8px;
  /* Dice pip size */
  height: 8px;
  background-color: #111;
  border-radius: 50%;
  opacity: 0;
  transform: scale(0);
  transition: all 0.2s ease 0.1s;
}

.is-active .pip-dot {
  opacity: 1;
  transform: scale(1);
}

/* Add inner shadow to the white pip for depth */
.toggle-pip::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  border-radius: 50%;
  box-shadow: inset 0 -2px 4px rgba(0, 0, 0, 0.1);
  pointer-events: none;
}
</style>
