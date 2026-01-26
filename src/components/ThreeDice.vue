<template>
    <div ref="canvasContainer" class="canvas-container"></div>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue';
import * as THREE from 'three';
import { RoundedBoxGeometry } from 'three/examples/jsm/geometries/RoundedBoxGeometry.js';
import gsap from 'gsap';

const canvasContainer = ref<HTMLElement | null>(null);
const isRolling = ref(false);
const emit = defineEmits(['roll-complete']);

// Three.js variables
let scene: THREE.Scene;
let camera: THREE.PerspectiveCamera;
let renderer: THREE.WebGLRenderer;
let dice: THREE.Mesh[] = [];
let animationFrameId: number;

// Dice configuration
const DIE_SIZE = 1.5;
const DIE_RADIUS = 0.2;

// Helper to draw pips
const drawPips = (ctx: CanvasRenderingContext2D, val: number, size: number, isBump: boolean) => {
    const r = size / 9;
    const c = size / 2;
    const q = size / 4;
    const tq = size * 0.75;

    if (isBump) {
        ctx.fillStyle = '#000000';
    } else {
        ctx.fillStyle = '#1a1a1a';
    }

    const drawDot = (x: number, y: number) => {
        ctx.beginPath();
        ctx.arc(x, y, r, 0, Math.PI * 2);
        ctx.fill();
    };

    if (val % 2 === 1) drawDot(c, c);
    if (val > 1) {
        drawDot(q, q);
        drawDot(tq, tq);
    }
    if (val > 3) {
        drawDot(tq, q);
        drawDot(q, tq);
    }
    if (val === 6) {
        drawDot(q, c);
        drawDot(tq, c);
    }
};

const createDieMaterial = (value: number): THREE.Material => {
    const size = 512;

    const canvasColor = document.createElement('canvas');
    canvasColor.width = size;
    canvasColor.height = size;
    const ctxColor = canvasColor.getContext('2d');

    if (ctxColor) {
        ctxColor.fillStyle = '#ffffff';
        ctxColor.fillRect(0, 0, size, size);
        drawPips(ctxColor, value, size, false);
    }

    const canvasBump = document.createElement('canvas');
    canvasBump.width = size;
    canvasBump.height = size;
    const ctxBump = canvasBump.getContext('2d');

    if (ctxBump) {
        ctxBump.fillStyle = '#ffffff';
        ctxBump.fillRect(0, 0, size, size);
        drawPips(ctxBump, value, size, true);
    }

    const texColor = new THREE.CanvasTexture(canvasColor);
    const texBump = new THREE.CanvasTexture(canvasBump);

    return new THREE.MeshStandardMaterial({
        map: texColor,
        bumpMap: texBump,
        bumpScale: 0.08,
        color: 0xffffff,
        roughness: 0.1,
        metalness: 0.0,
    });
};

const getTargetRotation = (faceValue: number) => {
    switch (faceValue) {
        case 1: return { x: 0, y: -Math.PI / 2, z: 0 };
        case 6: return { x: 0, y: Math.PI / 2, z: 0 };
        case 2: return { x: Math.PI / 2, y: 0, z: 0 };
        case 5: return { x: -Math.PI / 2, y: 0, z: 0 };
        case 3: return { x: 0, y: 0, z: 0 };
        case 4: return { x: Math.PI, y: 0, z: 0 };
        default: return { x: 0, y: 0, z: 0 };
    }
};

const initScene = () => {
    if (!canvasContainer.value) return;

    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x000000);

    const width = canvasContainer.value.clientWidth;
    const height = canvasContainer.value.clientHeight;
    camera = new THREE.PerspectiveCamera(40, width / height, 0.1, 100);
    camera.position.z = 12;

    renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setSize(width, height);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.0;

    canvasContainer.value.appendChild(renderer.domElement);

    const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
    scene.add(ambientLight);

    const dirLight = new THREE.DirectionalLight(0xffffff, 1.2);
    dirLight.position.set(5, 10, 8);
    scene.add(dirLight);

    const pointLight = new THREE.PointLight(0xffffff, 1.0);
    pointLight.position.set(-5, 5, 5);
    scene.add(pointLight);

    const materials = [
        createDieMaterial(1),
        createDieMaterial(6),
        createDieMaterial(2),
        createDieMaterial(5),
        createDieMaterial(3),
        createDieMaterial(4)
    ];

    const geometry = new RoundedBoxGeometry(DIE_SIZE, DIE_SIZE, DIE_SIZE, 8, DIE_RADIUS);

    const die1 = new THREE.Mesh(geometry, materials);
    const die2 = new THREE.Mesh(geometry, materials);

    die1.position.set(0, 1.2, 0);
    die2.position.set(0, -1.2, 0);

    dice = [die1, die2];
    scene.add(die1);
    scene.add(die2);

    dice.forEach(d => {
        d.rotation.x = Math.random() * Math.PI;
        d.rotation.y = Math.random() * Math.PI;
    });

    animate();
};

const animate = () => {
    animationFrameId = requestAnimationFrame(animate);
    if (renderer && scene && camera) {
        renderer.render(scene, camera);
    }
};

const roll = (): boolean => {
    if (isRolling.value) return false;
    isRolling.value = true;

    dice.forEach((die, index) => {
        const result = Math.floor(Math.random() * 6) + 1;
        const target = getTargetRotation(result);
        const spinsX = 2 + Math.floor(Math.random() * 3);
        const spinsY = 2 + Math.floor(Math.random() * 3);

        const currentX = die.rotation.x;
        const currentY = die.rotation.y;

        const targetX = target.x + (Math.ceil(currentX / (Math.PI * 2)) + spinsX) * Math.PI * 2;
        const targetY = target.y + (Math.ceil(currentY / (Math.PI * 2)) + spinsY) * Math.PI * 2;

        gsap.to(die.rotation, {
            x: targetX,
            y: targetY,
            z: target.z + (Math.random() - 0.5) * 0.2,
            duration: 1.2 + (index * 0.2),
            ease: 'power2.out',
            onComplete: () => {
                gsap.to(die.rotation, { z: target.z, duration: 0.3 });
                if (index === dice.length - 1) {
                    isRolling.value = false;
                    emit('roll-complete');
                }
            }
        });

        gsap.to(die.position, {
            z: die.position.z + 1.5,
            duration: 0.4,
            yoyo: true,
            repeat: 1,
            ease: 'power1.out'
        });
    });

    return true;
};

const handleResize = () => {
    if (!canvasContainer.value || !camera || !renderer) return;
    const width = canvasContainer.value.clientWidth;
    const height = canvasContainer.value.clientHeight;
    camera.aspect = width / height;
    camera.updateProjectionMatrix();
    renderer.setSize(width, height);
};

onMounted(() => {
    setTimeout(() => initScene(), 50);
    window.addEventListener('resize', handleResize);
});

onUnmounted(() => {
    window.removeEventListener('resize', handleResize);
    cancelAnimationFrame(animationFrameId);
    if (renderer) renderer.dispose();
    dice.forEach(d => { if (d.geometry) d.geometry.dispose(); });
});

defineExpose({
    roll
});

</script>

<style scoped>
.canvas-container {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
}
</style>
