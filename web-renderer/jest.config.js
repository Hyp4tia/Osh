module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'jest-environment-jsdom',
  moduleNameMapper: {
    '\\.(css|less|scss|sass)$': '<rootDir>/test/styleMock.js',
    '\\.wasm(\\?.*)?$': '<rootDir>/test/styleMock.js',
    '^markdown-it$': '<rootDir>/node_modules/markdown-it/dist/markdown-it.js',
    '^markdown-it-github-alerts$': '<rootDir>/test/__mocks__/markdown-it-github-alerts.js',
    '^vega$': '<rootDir>/test/__mocks__/vega.js',
    '^vega-lite$': '<rootDir>/test/__mocks__/vega-lite.js',
    '^@hpcc-js/wasm-graphviz$': '<rootDir>/test/__mocks__/@hpcc-js/wasm-graphviz.js',
    '^@firecrawl/anydoc-wasm$': '<rootDir>/test/__mocks__/@firecrawl/anydoc-wasm.js'
  },
  transformIgnorePatterns: [
    'node_modules/(?!tex2typst)'
  ],
  transform: {
    '^.+\\.tsx?$': ['ts-jest', {
      tsconfig: 'tsconfig.json',
      diagnostics: {
        ignoreCodes: [1343]
      }
    }],
    'node_modules/tex2typst/.+\\.js$': ['ts-jest', {
      tsconfig: 'tsconfig.json'
    }]
  }
};
