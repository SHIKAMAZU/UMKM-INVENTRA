import { Router } from 'express';
import { listStockMovements } from '../controllers/stock.controller.js';
import { authenticate } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { validate } from '../middlewares/validate.js';
import { stockMovementQuerySchema } from '../validators/stock.validator.js';

const router = Router();

router.use(authenticate);

router.get(
  '/',
  authorize('admin'),
  validate({ query: stockMovementQuerySchema }),
  listStockMovements
);

export default router;
