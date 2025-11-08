export default {
  testEnvironment: 'jsdom',
  roots: ['<rootDir>/spec/javascript'],
  testMatch: ['**/*_spec.js'],
  moduleNameMapper: {
    '^@hotwired/stimulus$': '<rootDir>/spec/javascript/__mocks__/stimulus.js'
  },
  transform: {},
  setupFilesAfterEnv: ['<rootDir>/spec/javascript/setup.js'],
  collectCoverageFrom: [
    'app/assets/javascript/**/*.js',
    '!app/assets/javascript/**/*.min.js'
  ]
}
