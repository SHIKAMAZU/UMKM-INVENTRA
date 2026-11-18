import cors from 'cors';
import express from 'express';
import morgan from 'morgan';
import { uploadRootDir } from './middlewares/upload.js';
import { errorHandler, notFound } from './middlewares/errorHandler.js';
import routes from './routes/index.js';

export const app = express();

app.disable('x-powered-by');
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));

if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

app.use('/uploads', express.static(uploadRootDir, { maxAge: '1d' }));

app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'REST API Sistem Manajemen Informasi Stok Barang Toko',
    data: { health: '/api/health' },
  });
});

app.use('/api', routes);

app.use(notFound);
app.use(errorHandler);
