import js from '@eslint/js';
import globals from 'globals';
import pluginVue from 'eslint-plugin-vue';
import vueTs from '@vue/eslint-config-typescript';

export default [
    {
        ignores: [
            '**/dist/**',
            '**/dist-ssr/**',
            '**/coverage/**',
            '**/node_modules/**',
            '**/.DS_Store',
            '**/ios/**',
            '**/android/**',
            '**/.env.*.local',
            '**/.env.local',
            '**/*-debug.log*',
            '**/*-error.log*',
            '**/.idea/**',
            '**/.vscode/**',
            '**/*.suo',
            '**/*.ntvs*',
            '**/*.njsproj',
            '**/*.sln',
            '**/*.sw?'
        ]
    },

    js.configs.recommended,
    ...pluginVue.configs['flat/essential'],
    ...vueTs({
        extends: [
            'recommended'
        ]
    }),

    {
        languageOptions: {
            globals: {
                ...globals.browser,
                ...globals.node
            },
            ecmaVersion: 2020,
            sourceType: 'module'
        },
        rules: {
            'no-console': process.env.NODE_ENV === 'production' ? 'warn' : 'off',
            'no-debugger': process.env.NODE_ENV === 'production' ? 'warn' : 'off',
            'vue/no-deprecated-slot-attribute': 'off',
            '@typescript-eslint/no-explicit-any': 'off',
            'vue/multi-word-component-names': 'off', // Common in ionic apps
            'no-useless-assignment': 'off', // False positives with Vue script setup
        }
    }
];
