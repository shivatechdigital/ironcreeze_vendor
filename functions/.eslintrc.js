// functions/.eslintrc.js
module.exports = {
    env: {
        es6: true,
        node: true,
    },
    parserOptions: {
        ecmaVersion: 2018,
    },
    extends: ["eslint:recommended", "google"],
    rules: {
        "no-restricted-globals": ["error", "name", "length"],
        "prefer-arrow-callback": "error",
        "quotes": ["error", "double", { allowTemplateLiterals: true }],
        "indent": ["error", 4],
        "max-len": "off",
        "no-multi-spaces": "off",
        "comma-dangle": "off",           // ← yeh band kar diya
        "object-curly-spacing": "off",   // ← yeh bhi band
        "require-jsdoc": "off",
        "arrow-parens": "off",
        "eol-last": "off",
    },
};