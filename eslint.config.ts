import js from '@eslint/js';
import prettier from 'eslint-plugin-prettier';
import parser from '@typescript-eslint/parser';
import importPlugin from 'eslint-plugin-import';
import typescript from '@typescript-eslint/eslint-plugin';

export default [
  {
    ignores: [
      'dist',
      'node_modules',
      'coverage',
      'build',
      'public',
      'deploy',
      'dependency-check-bin',
      'logs',
    ],
  },
  {
    files: ['**/*.ts'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      parser,
    },
    plugins: {
      '@typescript-eslint': typescript,
      prettier,
      js,
      import: importPlugin,
    },
    rules: {
      'prettier/prettier': 'error',
      '@typescript-eslint/no-explicit-any': 'warn',
      'no-console': process.env.NODE_ENV === 'production' ? 'warn' : 'off',
    },
  },
];
