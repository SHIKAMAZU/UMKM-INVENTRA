import { Router } from 'express';
import {
  createSupplier,
  deleteSupplier,
  getSupplier,
  listSuppliers,
  updateSupplier,
} from '../controllers/supplier.controller.js';
import { authenticate } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { validate } from '../middlewares/validate.js';
import { idParamSchema } from '../validators/common.validator.js';
import {
  createSupplierBodySchema,
  updateSupplierBodySchema,
} from '../validators/supplier.validator.js';

const router = Router();

router.use(authenticate);

router.get('/', listSuppliers);
router.get('/:id', validate({ params: idParamSchema }), getSupplier);
router.post(
  '/',
  authorize('admin'),
  validate({ body: createSupplierBodySchema }),
  createSupplier
);
router.put(
  '/:id',
  authorize('admin'),
  validate({ params: idParamSchema, body: updateSupplierBodySchema }),
  updateSupplier
);
router.delete(
  '/:id',
  authorize('admin'),
  validate({ params: idParamSchema }),
  deleteSupplier
);

export default router;
