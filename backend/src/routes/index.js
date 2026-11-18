import { Router } from 'express';
import { query } from '../db/pool.js';
import authRoutes from './auth.routes.js';
import categoryRoutes from './category.routes.js';
import productRoutes from './product.routes.js';
import saleRoutes from './sale.routes.js';
import stockRoutes from './stock.routes.js';
import supplierRoutes from './supplier.routes.js';
import userRoutes from './user.routes.js';

const router = Router();

router.get('/health', async (req, res, next) => {
  try {
    await query('SELECT 1');
    res.json({ success: true, message: 'API sehat', data: { database: 'connected' } });
  } catch (err) {
    next(err);
  }
});

router.use('/auth', authRoutes);
router.use('/categories', categoryRoutes);
router.use('/products', productRoutes);
router.use('/sales', saleRoutes);
router.use('/stock-movements', stockRoutes);
router.use('/suppliers', supplierRoutes);
router.use('/users', userRoutes);

export default router;
