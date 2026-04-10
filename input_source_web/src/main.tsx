import {StrictMode} from 'react';
import {createRoot} from 'react-dom/client';
import App from './App.tsx';
import './index.css';

const container = document.getElementById('app') || document.getElementById('root');

if (!container) {
  throw new Error("Target container is not a DOM element ('app' or 'root')");
}

createRoot(container).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
