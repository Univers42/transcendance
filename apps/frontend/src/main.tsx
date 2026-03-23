import { createRoot } from 'react-dom/client';
import { App } from './App';
import './app/styles/global.scss';

createRoot(document.getElementById('root')!).render(<App />);
