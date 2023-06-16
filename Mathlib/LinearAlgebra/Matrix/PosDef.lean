/-
Copyright (c) 2022 Alexander Bentkamp. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Alexander Bentkamp

! This file was ported from Lean 3 source module linear_algebra.matrix.pos_def
! leanprover-community/mathlib commit 07992a1d1f7a4176c6d3f160209608be4e198566
! Please do not edit these lines, except to modify the commit id
! if you have ported upstream changes.
-/
import Mathlib.LinearAlgebra.Matrix.Spectrum
import Mathlib.LinearAlgebra.QuadraticForm.Basic

/-! # Positive Definite Matrices
This file defines positive (semi)definite matrices and connects the notion to positive definiteness
of quadratic forms.
## Main definition
 * `Matrix.PosDef` : a matrix `M : Matrix n n 𝕜` is positive definite if it is hermitian and `xᴴMx`
   is greater than zero for all nonzero `x`.
 * `Matrix.PosSemidef` : a matrix `M : Matrix n n 𝕜` is positive semidefinite if it is hermitian
   and `xᴴMx` is nonnegative for all `x`.
-/


namespace Matrix

variable {𝕜 : Type _} [IsROrC 𝕜] {m n : Type _} [Fintype m] [Fintype n]

open scoped Matrix

/-- A matrix `M : Matrix n n 𝕜` is positive definite if it is hermitian
   and `xᴴMx` is greater than zero for all nonzero `x`. -/
def PosDef (M : Matrix n n 𝕜) :=
  M.IsHermitian ∧ ∀ x : n → 𝕜, x ≠ 0 → 0 < IsROrC.re (dotProduct (star x) (M.mulVec x))
#align matrix.pos_def Matrix.PosDef

theorem PosDef.isHermitian {M : Matrix n n 𝕜} (hM : M.PosDef) : M.IsHermitian :=
  hM.1
#align matrix.pos_def.is_hermitian Matrix.PosDef.isHermitian

/-- A matrix `M : Matrix n n 𝕜` is positive semidefinite if it is hermitian
   and `xᴴMx` is nonnegative for all `x`. -/
def PosSemidef (M : Matrix n n 𝕜) :=
  M.IsHermitian ∧ ∀ x : n → 𝕜, 0 ≤ IsROrC.re (dotProduct (star x) (M.mulVec x))
#align matrix.pos_semidef Matrix.PosSemidef

theorem PosDef.posSemidef {M : Matrix n n 𝕜} (hM : M.PosDef) : M.PosSemidef := by
  refine' ⟨hM.1, _⟩
  intro x
  by_cases hx : x = 0
  · simp only [hx, zero_dotProduct, star_zero, IsROrC.zero_re']
    exact le_rfl
  · exact le_of_lt (hM.2 x hx)
#align matrix.pos_def.pos_semidef Matrix.PosDef.posSemidef

theorem PosSemidef.submatrix {M : Matrix n n 𝕜} (hM : M.PosSemidef) (e : m ≃ n) :
    (M.submatrix e e).PosSemidef := by
  refine' ⟨hM.1.submatrix e, fun x => _⟩
  have : (M.submatrix (⇑e) e).mulVec x = (M.mulVec fun i : n => x (e.symm i)) ∘ e := by
    ext i
    dsimp only [(· ∘ ·), mulVec, dotProduct]
    rw [Finset.sum_bij' (fun i _ => e i) _ _ fun i _ => e.symm i] <;>
      simp only [eq_self_iff_true, imp_true_iff, Equiv.symm_apply_apply, Finset.mem_univ,
        submatrix_apply, Equiv.apply_symm_apply]
  rw [this]
  convert hM.2 fun i => x (e.symm i) using 3
  unfold dotProduct
  rw [Finset.sum_bij' (fun i _ => e i) _ _ fun i _ => e.symm i] <;>
  simp
#align matrix.pos_semidef.submatrix Matrix.PosSemidef.submatrix

@[simp]
theorem posSemidef_submatrix_equiv {M : Matrix n n 𝕜} (e : m ≃ n) :
    (M.submatrix e e).PosSemidef ↔ M.PosSemidef :=
  ⟨fun h => by simpa using h.submatrix e.symm, fun h => h.submatrix _⟩
#align matrix.pos_semidef_submatrix_equiv Matrix.posSemidef_submatrix_equiv

theorem PosDef.transpose {M : Matrix n n 𝕜} (hM : M.PosDef) : Mᵀ.PosDef := by
  refine' ⟨IsHermitian.transpose hM.1, fun x hx => _⟩
  convert hM.2 (star x) (star_ne_zero.2 hx) using 2
  rw [mulVec_transpose, Matrix.dotProduct_mulVec, star_star, dotProduct_comm]
#align matrix.pos_def.transpose Matrix.PosDef.transpose

theorem posDef_of_toQuadraticForm' [DecidableEq n] {M : Matrix n n ℝ} (hM : M.IsSymm)
    (hMq : M.toQuadraticForm'.PosDef) : M.PosDef := by
  refine' ⟨hM, fun x hx => _⟩
  simp only [toQuadraticForm', QuadraticForm.PosDef, BilinForm.toQuadraticForm_apply,
    Matrix.toBilin'_apply'] at hMq
  apply hMq x hx
#align matrix.pos_def_of_to_quadratic_form' Matrix.posDef_of_toQuadraticForm'

theorem posDef_toQuadraticForm' [DecidableEq n] {M : Matrix n n ℝ} (hM : M.PosDef) :
    M.toQuadraticForm'.PosDef := by
  intro x hx
  simp only [toQuadraticForm', BilinForm.toQuadraticForm_apply, Matrix.toBilin'_apply']
  apply hM.2 x hx
#align matrix.pos_def_to_quadratic_form' Matrix.posDef_toQuadraticForm'

namespace PosDef

variable {M : Matrix n n ℝ} (hM : M.PosDef)

theorem det_pos [DecidableEq n] : 0 < det M := by
  rw [hM.isHermitian.det_eq_prod_eigenvalues]
  apply Finset.prod_pos
  intro i _
  rw [hM.isHermitian.eigenvalues_eq]
  refine hM.2 _ fun h => ?_
  have h_det : hM.isHermitian.eigenvectorMatrixᵀ.det = 0 :=
    Matrix.det_eq_zero_of_row_eq_zero i fun j => congr_fun h j
  simpa only [h_det, not_isUnit_zero] using
    isUnit_det_of_invertible hM.isHermitian.eigenvectorMatrixᵀ
#align matrix.pos_def.det_pos Matrix.PosDef.det_pos

end PosDef

end Matrix

namespace QuadraticForm

variable {n : Type _} [Fintype n]

theorem posDef_of_toMatrix' [DecidableEq n] {Q : QuadraticForm ℝ (n → ℝ)}
    (hQ : Q.toMatrix'.PosDef) : Q.PosDef := by
  rw [← toQuadraticForm_associated ℝ Q, ← BilinForm.toMatrix'.left_inv ((associatedHom ℝ) Q)]
  apply Matrix.posDef_toQuadraticForm' hQ
#align quadratic_form.pos_def_of_to_matrix' QuadraticForm.posDef_of_toMatrix'

theorem posDef_toMatrix' [DecidableEq n] {Q : QuadraticForm ℝ (n → ℝ)} (hQ : Q.PosDef) :
    Q.toMatrix'.PosDef := by
  rw [← toQuadraticForm_associated ℝ Q, ←
    BilinForm.toMatrix'.left_inv ((associatedHom ℝ) Q)] at hQ
  apply Matrix.posDef_of_toQuadraticForm' (isSymm_toMatrix' Q) hQ
#align quadratic_form.pos_def_to_matrix' QuadraticForm.posDef_toMatrix'

end QuadraticForm

namespace Matrix

variable {𝕜 : Type _} [IsROrC 𝕜] {n : Type _} [Fintype n]

/-- A positive definite matrix `M` induces a norm `‖x‖ = sqrt (re xᴴMx)`. -/
@[reducible]
noncomputable def NormedAddCommGroup.ofMatrix {M : Matrix n n 𝕜} (hM : M.PosDef) :
    NormedAddCommGroup (n → 𝕜) :=
  @InnerProductSpace.Core.toNormedAddCommGroup _ _ _ _ _
    { inner := fun x y => dotProduct (star x) (M.mulVec y)
      conj_symm := fun x y => by
        dsimp only [Inner.inner]
        rw [star_dotProduct, starRingEnd_apply, star_star, star_mulVec, dotProduct_mulVec,
          hM.isHermitian.eq]
      nonneg_re := fun x => by
        by_cases h : x = 0
        · simp [h]
        · exact le_of_lt (hM.2 x h)
      definite := fun x (hx : dotProduct _ _ = 0) => by
        by_contra' h
        simpa [hx, lt_irrefl] using hM.2 x h
      add_left := by simp only [star_add, add_dotProduct, eq_self_iff_true, forall_const]
      smul_left := fun x y r => by
        simp only
        rw [← smul_eq_mul, ← smul_dotProduct, starRingEnd_apply, ← star_smul] }
#align matrix.normed_add_comm_group.of_matrix Matrix.NormedAddCommGroup.ofMatrix

/-- A positive definite matrix `M` induces an inner product `⟪x, y⟫ = xᴴMy`. -/
def InnerProductSpace.ofMatrix {M : Matrix n n 𝕜} (hM : M.PosDef) :
    @InnerProductSpace 𝕜 (n → 𝕜) _ (NormedAddCommGroup.ofMatrix hM) :=
  InnerProductSpace.ofCore _
#align matrix.inner_product_space.of_matrix Matrix.InnerProductSpace.ofMatrix

end Matrix