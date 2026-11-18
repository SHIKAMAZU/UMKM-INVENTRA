import { Router } from 'express';
import { createSale, deleteSale, listSales } from '../controllers/sale.controller.js';
import { authenticate } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { validate } from '../middlewares/validate.js';
import { idParamSchema, paginationQuerySchema } from '../validators/common.validator.js';
import { createSaleBodySchema } from '../validators/sale.validator.js';

const router = Router();

router.use(authenticate);

router.get(
  '/',
  authorize('admin', 'staff'),
  validate({ query: paginationQuerySchema }),
  listSales
);

router.post(
  '/',
  authorize('admin', 'staff'),
  validate({ body: createSaleBodySchema }),
  createSale
);

router.delete(
  '/:id',
  authorize('admin'),
  validate({ params: idParamSchema }),
  deleteSale
);

export default router;
