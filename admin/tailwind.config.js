/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      fontFamily: { sans: ['"DM Sans"', 'system-ui', 'sans-serif'] },
      colors: {
        brand: { 50: '#FFF4EE', 100: '#FFE6D6', 200: '#FFC8A8', 300: '#FFA273', 400: '#FE8547', 500: '#FD6B22', 600: '#E85410', 700: '#C1420B', 800: '#98360F', 900: '#7A2F10' },
        ink: { 50: '#F6F6F8', 100: '#EDEDF0', 200: '#DCDCE1', 300: '#B9BAC2', 400: '#8E9099', 500: '#6B6D76', 600: '#4D4F57', 700: '#33353C', 800: '#24262C', 850: '#1E2025', 900: '#1B1D21', 950: '#121316' },
      },
      boxShadow: { card: '0 1px 2px rgba(16,17,20,.04), 0 4px 16px rgba(16,17,20,.04)' },
    },
  },
  plugins: [],
}
