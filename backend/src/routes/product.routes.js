import { Router } from 'express';
import {
  createProduct,
  deleteProduct,
  getProduct,
  listProducts,
  updateProduct,
  uploadProductImage,
} from '../controllers/product.controller.js';
import { createStockMovement } from '../controllers/stock.controller.js';
import { authenticate } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { uploadProductImage as uploadImage } from '../middlewares/upload.js';
import { validate } from '../middlewares/validate.js';
import { idParamSchema } from '../validators/common.validator.js';
import {
  createProductBodySchema,
  productQuerySchema,
  updateProductBodySchema,
} from '../validators/product.validator.js';
import { createStockMovementBodySchema } from '../validators/stock.validator.js';

const router = Router();

router.use(authenticate);

router.get('/', validate({ query: productQuerySchema }), listProducts);
router.get('/:id', validate({ params: idParamSchema }), getProduct);

router.post('/', authorize('admin'), validate({ body: createProductBodySchema }), createProduct);
router.put(
  '/:id',
  authorize('admin'),
  validate({ params: idParamSchema, body: updateProductBodySchema }),
  updateProduct
);
router.delete('/:id', authorize('admin'), validate({ params: idParamSchema }), deleteProduct);

router.post(
  '/:id/image',
  authorize('admin'),
  validate({ params: idParamSchema }),
  uploadImage,
  uploadProductImage
);

router.post(
  '/:id/stock',
  authorize('admin', 'staff'),
  validate({ params: idParamSchema, body: createStockMovementBodySchema }),
  createStockMovement
);

export default router;
