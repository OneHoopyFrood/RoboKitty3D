module.exports = {
  root: true,
  plugins: ['deprecation', 'prettier', 'no-only-tests'],
  extends: ['eslint:recommended'],
  env: {
    node: true,
    es2018: true,
  },
  ignorePatterns: ['/**/dist/**/*'],
  rules: {
    // NOTE: if you're failing this check, you can run 'yarn lint --fix' and prettier rules will be applied
    'prettier/prettier': 'error',
    'no-console': 2,
    'prefer-const': 2,
    'no-unused-vars': 2,
    eqeqeq: ['error', 'smart'],
    'no-async-promise-executor': 0,
    'prefer-rest-params': 2,
    'no-constant-condition': 2,
    'no-useless-catch': 2,
    'no-cond-assign': 2,
    'no-throw-literal': 2,
    'no-shadow': 2, // Note, this needs to be disabled for enums
    'no-restricted-globals': [
      'error',
      {
        name: 'fdescribe',
        message: 'Only use fdescribe for local testing, replace with describe() before committing',
      },
      {
        name: 'fit',
        message: 'Only use fit for local testing, replace with it() before committing',
      },
    ],
    'no-only-tests/no-only-tests': 'error',
  },
  overrides: [
    {
      files: ['packages/**/*.ts', 'packages/**/*.tsx'],
      env: { browser: true, es6: true, node: true },
      extends: [
        'eslint:recommended',
        'plugin:@typescript-eslint/eslint-recommended',
        'plugin:@typescript-eslint/recommended',
      ],
      globals: { Atomics: 'readonly', SharedArrayBuffer: 'readonly' },
      parser: '@typescript-eslint/parser',
      parserOptions: {
        ecmaVersion: 2018,
        sourceType: 'module',
        project: ['packages/*/tsconfig.json', 'tsconfig.eslint.json'],
      },
      plugins: ['@typescript-eslint'],
      rules: {
        'no-shadow': 'off',
        '@typescript-eslint/no-shadow': 'error',
        'deprecation/deprecation': 'warn',
        '@typescript-eslint/no-inferrable-types': 0,
        '@typescript-eslint/ban-ts-comment': 0,
        '@typescript-eslint/no-floating-promises': 2,
        indent: ['error', 2, { SwitchCase: 1, ignoredNodes: ['PropertyDefinition'] }],
        'linebreak-style': ['error', 'unix'],
        quotes: ['error', 'single'],
        'comma-dangle': ['error', 'always-multiline'],
        '@typescript-eslint/no-explicit-any': 0,
      },
    },
  ],
}
