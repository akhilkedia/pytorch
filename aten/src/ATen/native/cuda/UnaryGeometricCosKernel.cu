#define TORCH_ASSERT_NO_OPERATORS
#include <ATen/AccumulateType.h>
#include <ATen/Dispatch.h>
#include <ATen/OpMathType.h>
#include <ATen/native/DispatchStub.h>
#include <ATen/native/TensorIterator.h>
#include <ATen/native/UnaryOps.h>
#include <ATen/native/cuda/Loops.cuh>
#include <ATen/native/cuda/Math.cuh>
#include <limits>

namespace at::native {

const char cos_name[] = "cos";
void cos_kernel_cuda(TensorIteratorBase& iter) {
  auto common_dtype = iter.common_dtype();
  if (at::isComplexType(common_dtype)) {
#if AT_USE_JITERATOR
    static const auto cos_string = jiterator_stringify(
        template <typename T> T cos(T a) { return std::cos(a); });
    AT_DISPATCH_COMPLEX_TYPES_AND(
        kComplexHalf, common_dtype, "cos_name", [&]() {
          jitted_gpu_kernel<
              /*name=*/cos_name,
              /*return_dtype=*/scalar_t,
              /*common_dtype=*/scalar_t,
              /*arity=*/1>(iter, cos_string);
        });
#else
    AT_DISPATCH_COMPLEX_TYPES_AND(
        kComplexHalf, common_dtype, "cos_name", [&]() {
          gpu_kernel(iter, [] GPU_LAMBDA(scalar_t a) -> scalar_t {
            using opmath_t = at::opmath_type<scalar_t>;
            return ::cos(static_cast<opmath_t>(a));
          });
        });
#endif
  } else {
    AT_DISPATCH_FLOATING_TYPES_AND2(
        ScalarType::Half,
        ScalarType::BFloat16,
        common_dtype,
        "cos_cuda",
        [&]() {
          gpu_kernel(
              iter, [] GPU_LAMBDA(scalar_t a) -> scalar_t { return ::cos(a); });
        });
  }
}

REGISTER_DISPATCH(cos_stub, &cos_kernel_cuda);

} // namespace at::native
