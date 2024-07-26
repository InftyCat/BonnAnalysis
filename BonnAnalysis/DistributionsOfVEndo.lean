import Mathlib.Topology.Sequences
import Mathlib.Topology.Defs.Filter
import Mathlib.Topology.Order
import Mathlib.Topology.Algebra.ContinuousAffineMap
import Mathlib.Order.Filter.Basic
import Mathlib.Init.Function
import BonnAnalysis.ConvergingSequences
import Mathlib.Geometry.Manifold.Instances.Real
import Mathlib.Topology.UniformSpace.UniformConvergence
import Mathlib.Data.Set.Pointwise.Basic
import BonnAnalysis.UniformConvergenceSequences
import BonnAnalysis.Distributions
import Mathlib

import Mathlib.Analysis.Convolution
--import Mathlib.Analysis.InnerProductSpace
-- import Mathlib.Order
-- noncomputable section
--open FourierTransform MeasureTheory Real


namespace MeasureTheory
open MeasureTheory
open scoped Pointwise
universe u v w u'
open Order Set

open scoped Classical
open NNReal Topology
open Filter

open scoped Topology
open TopologicalSpace
noncomputable section
open Function

variable (k : Type v) [NontriviallyNormedField k]

open ContinuousLinearEquiv
/-
Unfortunately I have some universe issues and have to assume V lives in 0.th universe
-/
variable  {V : Type}  [MeasurableSpace V] [NormedAddCommGroup V]  [NormedSpace k V]
@[simp] def reflection' : V →ᴬ[k] V := (ContinuousLinearMap.neg.neg (ContinuousLinearMap.id k V)).toContinuousAffineMap
@[simp] def shift' (x : V) : V →ᴬ[k] V := by
  apply ContinuousAffineMap.mk ; swap ;
  refine AffineMap.mk (fun y => y - x ) (LinearMap.id (R:=k) (M:=V)) ?_
  intro p v ; simp ; exact add_sub_assoc v p x
  apply Continuous.sub
  exact continuous_id'
  exact continuous_const
lemma properNessOfHomeo  {X : Type*} {Y : Type*} [TopologicalSpace X] [TopologicalSpace Y]
  (e : ContinuousMap X Y) (f : ContinuousMap Y X) (hf : ∀ x , (f ∘ e) x = x) (hf2 : ∀ x , e ( f x) = x):
  IsProperMap e := Homeomorph.isProperMap (by use ⟨ e , f , hf  , hf2⟩ ; continuity ; continuity)

lemma reflectionIsProper : IsProperMap (reflection' k : V → V) :=

  by
    have : ∀ (x : V), (⇑(reflection' k).toContinuousMap ∘ ⇑(reflection' k).toContinuousMap) x = x := by
      intro x ; simp only [reflection', ContinuousAffineMap.toContinuousMap_coe,
      ContinuousMap.coe_coe, ContinuousLinearMap.coe_toContinuousAffineMap, comp_apply,
      ContinuousLinearMap.neg_apply, ContinuousLinearMap.coe_id', id_eq, _root_.map_neg, neg_neg]
    apply properNessOfHomeo (reflection' k).toContinuousMap (reflection' k).toContinuousMap
    exact this
    exact this

instance shiftIsProper (v : V) :   IsProperMap ((shift' k v) : V → V) :=  by

    apply properNessOfHomeo (shift' k v).toContinuousMap (shift' k (-v)).toContinuousMap
    · intro x ; simp only [shift', sub_neg_eq_add, ContinuousAffineMap.toContinuousMap_coe,
      ContinuousMap.coe_coe, ContinuousAffineMap.coe_mk, AffineMap.coe_mk, comp_apply,
      sub_add_cancel]
    · intro x ; simp only [shift', ContinuousAffineMap.toContinuousMap_coe, sub_neg_eq_add,
      ContinuousMap.coe_coe, ContinuousAffineMap.coe_mk, AffineMap.coe_mk, add_sub_cancel_right]

variable {V : Type} {k : Type v} [NontriviallyNormedField k]
  [MeasurableSpace V] [NormedAddCommGroup V]  [NormedSpace k V] {Ω : Opens V}


variable  (W : Type* )  [NormedAddCommGroup W]  [NormedSpace k W]

@[simp] def ev_cts  (v : V) {W : Type* }  [NormedAddCommGroup W]  [NormedSpace k W]  :
  (V →L[k] W) →L[k] W := ContinuousLinearMap.apply _ _ v


-- open LinearMap





open 𝓓
lemma supportfromEndoOfV (Φ : V →ᴬ[k] V)  (ψ : 𝓓F k V) : tsupport (ψ ∘ Φ) ⊆ Φ ⁻¹' (tsupport ψ ) := by

  have ( A : Set V ) : closure (Φ ⁻¹' (A)) ⊆ Φ ⁻¹' (closure A) := by
    apply Continuous.closure_preimage_subset
    apply Φ.cont
  apply this (ψ ⁻¹' {x | x ≠ 0})
lemma tsupport_comp_subset {M N α : Type*} [TopologicalSpace α ] [TopologicalSpace M] [TopologicalSpace N] [Zero M] [Zero N] {g : M → N} (hg : g 0 = 0) (f : α → M) :
    tsupport (g ∘ f) ⊆ tsupport f := by
        apply closure_minimal
        · trans support f
          · apply support_comp_subset ; exact hg
          · exact subset_tsupport f
        · exact isClosed_tsupport f
open Convolution

section CommGroup
lemma add_compact_subsets {G : Type*} [AddCommGroup G]  [TopologicalSpace G] [TopologicalAddGroup G] {A B : Set G} (hA : IsCompact A) (hB : IsCompact B)
  : IsCompact (A + B ) := by
    let plus : G × G → G := fun p  => p.1 + p.2
    have check : plus '' (A ×ˢ B) = A + B := add_image_prod
    rw [← check]
    apply IsCompact.image
    exact IsCompact.prod hA hB

    exact continuous_add
lemma sub_compact_subsets {G : Type*} [AddCommGroup G]  [TopologicalSpace G] [TopologicalAddGroup G] {A B : Set G} (hA : IsCompact A) (hB : IsCompact B)
  : IsCompact (A - B ) := by
    let plus : G × G → G := fun p  => p.1 - p.2
    have check : plus '' (A ×ˢ B) = A - B := sub_image_prod
    rw [← check]
    apply IsCompact.image
    exact IsCompact.prod hA hB

    exact continuous_sub
  -- use that images of compact subsets under + : G x G → G are compact.
lemma tsupport_convolution_subset {𝕜 : Type*}[NontriviallyNormedField 𝕜] {G : Type*} [MeasurableSpace G] (μ : Measure G) {E : Type*} {E' : Type*}  {F : Type*}
  [NormedAddCommGroup F] [NormedAddCommGroup E] [NormedAddCommGroup E']
   [NormedSpace 𝕜 E] [NormedSpace 𝕜 E'] [NormedSpace 𝕜 F] [NormedSpace ℝ F]
  [AddCommGroup G]  [TopologicalSpace G]  [TopologicalAddGroup G]  [T2Space G]
 (L : E →L[𝕜] E' →L[𝕜] F) {f : G → E} {g : G → E'} (hf : HasCompactSupport f) (hg : HasCompactSupport g) : tsupport (f ⋆[L, μ] g) ⊆ tsupport f + tsupport g:=by
  apply closure_minimal
  · trans support f + support g
    · apply support_convolution_subset
    · have a1 := subset_tsupport (f)
      have a2 := subset_tsupport g
      exact add_subset_add a1 a2
  · have : IsCompact ( tsupport f + tsupport g) := by
      apply add_compact_subsets
      exact hf
      exact hg
    -- maybe use that compact subsets of metrizable spaces are closed?
    exact IsCompact.isClosed this

-- lemma affineAsUnderlyingLinearTransition {Φ : V →ᴬ[k] V} {v : V} : Φ v = (Φ.linear v) + Φ 0 := by  rw [show Φ v = Φ (v + 0) from by simp only [add_zero]] ; apply Φ.map_vadd'
-- def precompmyΦ (Φ : V →ᴬ[k] V) (l : ℕ) : (V [×l]→L[k] k) →L[k] (V [×l]→L[k] k) := ContinuousMultilinearMap.compContinuousLinearMapL  fun _ ↦ Φ.contLinear
def precompmyΦ (Φ : V →ᴬ[k] V) (l : ℕ) : (V [×l]→L[k] k) →L[k] (V [×l]→L[k] k) := ContinuousMultilinearMap.compContinuousLinearMapL (fun _ ↦ Φ.contLinear)
--(W : Type* )  [NormedAddCommGroup W]  [NormedSpace k W]
lemma affineAsUnderlyingLinearTransition  {Φ : V →ᴬ[k] V} {v : V} : Φ v = (Φ.linear v) + Φ 0 := by  rw [show Φ v = Φ (v + 0) from by simp only [add_zero]] ; apply Φ.map_vadd'
-- lemma fderiv_iteratedFDeriv'
lemma fDerivTransition  (v x : V) (φ0 : V → W) (hφ0 : ContDiff k ⊤ φ0):
  fderiv k (φ0.comp (shift' k v)) (x) = fderiv k φ0 (x - v) := by
    rw [fderiv.comp ] -- , AffineMap.deriv (shift' k v)]
    · have : (fderiv k (⇑(shift' k v)) x) = ContinuousLinearMap.id k V := by
         calc
          fderiv k (⇑(shift' k v)) x = fderiv k ((fun x => x) - (fun _ => v)) x := by congr
          _ =  fderiv k (id) x - fderiv k (fun _ => v) x := by apply fderiv_sub ; exact differentiableAt_id' ;  apply differentiableAt_const
          _ = _ := by rw [fderiv_id ,fderiv_const] ; simp only [Pi.zero_apply, sub_zero]
      rw [this]
      simp only [shift', ContinuousAffineMap.coe_mk, AffineMap.coe_mk, ContinuousLinearMap.comp_id]
    · apply  Differentiable.differentiableAt
      exact ContDiff.differentiable hφ0  (OrderTop.le_top 1)
    · apply Differentiable.differentiableAt
      apply ContDiff.differentiable ; swap
      · exact OrderTop.le_top _
      · exact ContinuousAffineMap.contDiff (𝕜 := k) (shift' k v)

lemma iteratedFDerivTransition  (v x : V) (l) (φ0 : 𝓓F k V) : -- V[×ℓ]→L[ k ] k) (l : ℕ)   :{ℓ : ℕ }
  iteratedFDeriv k (l) (φ0.φ.f.comp (shift' k v)) (x) = iteratedFDeriv k l φ0 (x - v) := by

    induction' l with l hl generalizing x -- φ0  ℓ
    · simp ; ext z ; rw [iteratedFDeriv_zero_apply , iteratedFDeriv_zero_apply] ; apply congrArg ; rfl

    · have {ψ : V → k} {l}:  (fun f => f.uncurryLeft) ∘ (fderiv k (iteratedFDeriv k l ψ)) =
        iteratedFDeriv k (l + 1) ψ  := by
          symm ;
          rw [fderiv_iteratedFDeriv] ;
          congr

      rw [← this]
      symm ;
      rw [← this]
      simp only [Nat.succ_eq_add_one, comp_apply, shift', ContinuousAffineMap.coe_mk,
        AffineMap.coe_mk]

      ext1 m
      simp
      apply congrFun
      apply congrArg
      apply congrFun
      apply congrArg
      let ψ := iteratedFDeriv k l φ0
      have : fderiv k (ψ.comp (shift' k v)) (x) = fderiv k ψ (x - v) := by
        apply fDerivTransition
        apply ContDiff.iteratedFDeriv_right
        exact φ0.φIsSmooth
        apply OrderTop.le_top
      rw [←  this]
      congr
      ext1 r
      simp
      exact Eq.symm (hl r)







-- This is a version of iteratedFDeriv_comp_right for continuous affine maps.
theorem ContinuousAffineMap.iteratedFDeriv_comp_right {l} {φ0 : 𝓓F k V} (Φ : V →ᴬ[k] V) {x} : (iteratedFDeriv k l (φ0 ∘ Φ)) x =
          (precompmyΦ Φ l) (iteratedFDeriv k l (φ0).φ (Φ x) ) := by
          let φ0' : V → k := (φ0.φ.f ).comp ((shift' k (- Φ 0)))
          have : φ0 ∘ Φ =  φ0' ∘ Φ.contLinear := by
            ext x ;  simp only [φ0',Function.comp_apply,
            shift', sub_neg_eq_add, ContinuousAffineMap.coe_mk, AffineMap.coe_mk,
            ContinuousAffineMap.coe_contLinear] ; congr ; apply affineAsUnderlyingLinearTransition
          rw [this]
          ext1 y
          rw [ContinuousLinearMap.iteratedFDeriv_comp_right (i:=l) (Φ.contLinear) ?_ _ (OrderTop.le_top _)]
          · have lol : ((iteratedFDeriv k l φ0' (Φ.contLinear x)).compContinuousLinearMap fun _ ↦ Φ.contLinear) =
            ⇑(precompmyΦ Φ l) (iteratedFDeriv k l φ0' (Φ.contLinear x)) := by unfold precompmyΦ ; rw [ContinuousMultilinearMap.compContinuousLinearMapL_apply]
            rw [lol]
            simp
            apply congrFun
            apply congrArg
            apply congrArg
            rw [affineAsUnderlyingLinearTransition]
            rw [show Φ.linear x + Φ 0 = Φ.linear x - (- Φ 0) from ?_]
            rw [iteratedFDerivTransition]

            simp only [sub_neg_eq_add]
          · have : ContDiff k ⊤ ⇑(shift' k (-Φ 0)) := by apply ContinuousAffineMap.contDiff

            refine ContDiff.comp φ0.φIsSmooth (this)


theorem chainRule {l} {φ0 : 𝓓F k V} (Φ : V →ᴬ[k] V) : (iteratedFDeriv k l (φ0 ∘ Φ)) =
          (precompmyΦ Φ l ∘ (iteratedFDeriv k l (φ0).φ ∘ Φ )) := by ext1 x ; exact ContinuousAffineMap.iteratedFDeriv_comp_right Φ

@[simp] def fromEndoOfV  (Φ : V →ᴬ[k] V)  (hΦ : IsProperMap (Φ : V → V)): 𝓓F k V →L[k] 𝓓F k V := by

  apply mk ; swap
  ·   intro ψ
      use ⟨ ψ ∘ Φ ,
       ContDiff.comp ψ.φIsSmooth (ContinuousAffineMap.contDiff  Φ ) , by
        apply IsCompact.of_isClosed_subset ; swap
        exact isClosed_tsupport (ψ.φ ∘ Φ)
        swap
        · exact supportfromEndoOfV (k:=k)  Φ ψ
        · apply IsProperMap.isCompact_preimage
          apply (hΦ)
          exact (ψ.φHasCmpctSupport) ⟩
      · exact fun _ _ ↦ trivial
      --ψ.φHasCmpctSupport
  · constructor
    · intro φ ψ
      ext x
      rfl
    · intro c φ
      ext x
      rfl
    · constructor
      intro φ φ0 hφ
      obtain ⟨ ⟨ K , hK⟩  ,hφ ⟩ := hφ
      apply tendsTo𝓝
      constructor
      · use Φ ⁻¹' K
        constructor
        · apply IsProperMap.isCompact_preimage
          apply hΦ
          exact hK.1
        · intro n
          trans
          · exact supportfromEndoOfV (k:=k) Φ (φ n)
          · apply Set.monotone_preimage
            exact hK.2 n

      · intro l
        -- apply TendstoUniformly.comp






        have : (fun n => iteratedFDeriv k l ((φ n).φ ∘ Φ) ) = (fun n => precompmyΦ Φ l ∘ iteratedFDeriv k l (φ n).φ ∘ Φ )  := by
           ext1 n
           apply chainRule
        have : TendstoUniformly (fun n => iteratedFDeriv k l (φ n ∘ Φ) ) (iteratedFDeriv k l (φ0 ∘ Φ)) atTop := by
          rw [chainRule (φ0 := φ0)]
          rw [this]
          apply UniformContinuous.comp_tendstoUniformly (g:= precompmyΦ Φ l)
          · apply ContinuousLinearMap.uniformContinuous -- apply UniformFun.postcomp_uniformContinuous , uniform Inducing?
          · apply TendstoUniformly.comp
            exact hφ l
        exact this



def δ : 𝓓' k Ω := mk k (fun φ => φ 0) (by
  constructor
  · intro x y ; rfl
  · intro c x ; rfl
  · constructor
    intro x a hx
    apply TendstoUniformly.tendsto_at
    have := hx.2 0
    apply (zeroCase k).mp
    assumption
    )
lemma testfunctionIsDiffAt {φ : 𝓓 k Ω} (x : V) : DifferentiableAt k (φ) x := by
  apply ContDiffAt.differentiableAt
  · apply contDiff_iff_contDiffAt.mp
    exact φ.φIsSmooth
  · exact OrderTop.le_top 1
variable {V : Type u} {k : Type v} [NontriviallyNormedField k] [NormedAddCommGroup V]
  [NormedSpace k V] {k' : Type u'} [NormedAddCommGroup k'] [NormedSpace k k'] (φ : ContCompactSupp k V k') (φ : ContCompactSupp k V k')
lemma obs' {φ : V → k'} : tsupport (fun x => fderiv k φ x ) ⊆ tsupport (φ) := by -- ⊆ tsupport (fun x => fderiv k φ) :=
    exact tsupport_fderiv_subset k (f:= φ)

lemma obs {v : V} {φ : V → k'} : tsupport (fun x => fderiv k φ x v) ⊆ tsupport (φ) := by -- ⊆ tsupport (fun x => fderiv k φ) :=
    trans ; swap
    · exact tsupport_fderiv_subset k (f:= φ)
    · apply tsupport_comp_subset rfl (g := fun f => f v)  (f:=fderiv k φ)
@[simp] def fderivCCS : ContCompactSupp k V (V →L[k] k') := by

    use fderiv k φ.f
    · have dfh : ContDiff k ⊤ (fun x => fderiv k φ.f x) := (contDiff_top_iff_fderiv.mp (φ.smooth )).2
      exact dfh
      -- have evvh : ContDiff k ⊤ (ContinuousLinearMap.apply k k' v  ) := by apply ContinuousLinearMap.contDiff

      -- apply ContDiff.comp  evvh dfh


    · apply IsCompact.of_isClosed_subset (φ.hsupp)
      exact isClosed_tsupport _
      exact obs'
variable {V : Type } {k : Type v} [NontriviallyNormedField k] [NormedAddCommGroup V]
  [NormedSpace k V] {k' : Type u'} [NormedAddCommGroup k'] [NormedSpace k k'] (φ : ContCompactSupp k V k') (φ : ContCompactSupp k V k') {Ω : Opens V}
def fderivCCSAt  (φ : ContCompactSupp k V k') (v : V): ContCompactSupp k V k' := by

    use fun x => fderiv k φ.f x v
    · have dfh : ContDiff k ⊤ (fun x => fderiv k φ.f x) := (contDiff_top_iff_fderiv.mp (φ.smooth )).2

      have evvh : ContDiff k ⊤ (ContinuousLinearMap.apply k k' v  ) := by apply ContinuousLinearMap.contDiff

      apply ContDiff.comp  evvh dfh


    · apply IsCompact.of_isClosed_subset (φ.hsupp)
      exact isClosed_tsupport _
      exact obs
def fderiv𝓓 (v : V) : (𝓓 k Ω) →L[k] 𝓓 k Ω := by
  have crypto {l} {ψ : 𝓓 k Ω} :
  /-
   iteratedFDeriv 𝕜 (n + 1) f =
    (⇑(continuousMultilinearCurryRightEquiv' 𝕜 n E F) ∘ iteratedFDeriv 𝕜 n fun y ↦ fderiv 𝕜 f y)
  -/
    iteratedFDeriv k l (fun y => fderiv k ψ.φ y v)  =
       (fun f => ( ev_cts v).compContinuousMultilinearMap f) ∘ fun z =>  (iteratedFDeriv k (l + 1) (ψ).φ z).curryRight  := by
            ext1 z ;
            simp_rw [iteratedFDeriv_succ_eq_comp_right]
            ext1 w
            simp only [ev_cts, Nat.succ_eq_add_one, Function.comp_apply,
              ContinuousLinearMap.compContinuousMultilinearMap_coe, ContinuousLinearMap.apply_apply,
              ContinuousMultilinearMap.curryRight_apply,
              continuousMultilinearCurryRightEquiv_apply', Fin.init_snoc, Fin.snoc_last]

            calc
                  _ = (iteratedFDeriv k l ((⇑(ev_cts (W:=k) v)).comp (fderiv k ψ)) z) w := by rfl
                  _ = (ev_cts v).compContinuousMultilinearMap (iteratedFDeriv k l (fderiv k ψ) z) w := ?_
                  _ = ((ev_cts v).toFun.comp ((iteratedFDeriv k l (fderiv k ψ) z))) w  := by rfl
                  _ = ((iteratedFDeriv k l (fderiv k ψ) z) w) v := by rfl
            · apply congrFun
              rw [ContinuousLinearMap.iteratedFDeriv_comp_left (f:= fderiv k ψ) (ev_cts (W:= k) v) (i:=l)  ]
              · apply ContDiff.fderiv_right
                · exact ψ.φIsSmooth
                · apply OrderTop.le_top


              · exact (OrderTop.le_top _)


  let f : 𝓓 k Ω → 𝓓 k Ω := fun φ => ⟨ fderivCCSAt φ.φ v , by
          trans
          · exact obs
          · exact φ.sprtinΩ ⟩
  apply mk ; swap
  · exact f
  · constructor
    ·     intro φ ψ
          ext x
          by_cases p : x ∈ Ω ; swap
          · trans (fderiv k φ x + fderiv k ψ x) v
            · apply congrFun (congrArg DFunLike.coe ?_) v ; apply fderiv_add ; apply testfunctionIsDiffAt ;apply testfunctionIsDiffAt ;
            · rfl

          · have : (fderiv k (fun y => φ.φ y + ψ.φ y) x) = (fderiv k φ.φ x) + (fderiv k ψ.φ x) := by
              apply fderiv_add
              · exact diffAt k Ω φ
              · exact diffAt k Ω ψ
            have obv : ((fderiv k (fun y => φ.φ y + ψ.φ y) x)) v = (fderiv k φ.φ x) v + (fderiv k ψ.φ x) v := by
              rw [this]
              rfl
            exact obv
    · intro c φ
      ext x
      simp
      trans (c • (fderiv k φ.φ x)) v
      · apply congrFun (congrArg DFunLike.coe ?_) v
        apply fderiv_const_smul (E:=V) (f:= φ.φ) (𝕜 := k) (R:=k) (F:=k) (x:=x) ?_ c
        apply testfunctionIsDiffAt
      · rfl
    · constructor
      intro α  a hx
      apply tendsTo𝓝
      constructor
      · obtain ⟨ K , hK ⟩ := hx.1
        use K
        constructor
        · exact hK.1
        · intro n
          trans (tsupport (α n).φ)
          · exact obs
          · exact hK.2 n
      · intro l
        have : TendstoUniformly (fun n ↦ iteratedFDeriv k (l+1) (α  n).φ) (iteratedFDeriv k (l+1) (a).φ) atTop := hx.2 (l+1)
        let g1 : (V[×(l+1)]→L[k] k) ≃ₗᵢ[k] (V[×l]→L[k] V →L[k] k) := (continuousMultilinearCurryRightEquiv k (fun _ => V) k).symm
        let g1 : (V[×(l+1)]→L[k] k) →L[k] (V[×l]→L[k] V →L[k] k)  := ContinuousLinearEquiv.toContinuousLinearMap g1
        let precomp_ev_v : (V[×l]→L[k] V →L[k] k) →L[k] (V[×l]→L[k] k) :=ContinuousLinearMap.compContinuousMultilinearMapL k (fun _ => V) (V →L[k] k) k  ( ev_cts v)
        let g : (V[×(l+1)]→L[k] k) →L[k] (V[×l]→L[k] k)  :=  precomp_ev_v.comp g1
    --     have step (f : V → k ) (z : V) : iteratedFDeriv k l (fderiv k f) z =
    -- ContinuousMultilinearMap.curryLeft (iteratedFDeriv k (l + 1) f z) := congrFun (fderiv_iteratedFDeriv (𝕜 := k) (f:= f)) z
        have hxg (ψ : 𝓓 k Ω)  :  iteratedFDeriv k l (f ψ).φ = g ∘ iteratedFDeriv k (l + 1) (ψ).φ := by
          calc
           _ = iteratedFDeriv k l (fun y => fderiv k ψ.φ y v) := rfl
           --_ = fun z => (ContinuousMultilinearMap.curryRight v (iteratedFDeriv k (l + 1) ψ.φ z)) := crypto
           _ = g ∘ iteratedFDeriv k (l + 1) (ψ).φ := crypto -- ext1 z ; simp





        rw [hxg]
        have hxg :  (fun (n : ℕ) => iteratedFDeriv k l ((f ∘ α ) n).φ) =
          fun (n : ℕ) => g ∘ (iteratedFDeriv k (l + 1) (α  n).φ) := by
            ext1 n
            exact hxg (α n)


        rw [hxg]

        --rw [← tendstoUniformlyOn_univ ] at this
        --rw [← tendstoUniformlyOn_univ ]
        have hg : UniformContinuous g.1 := by apply ContinuousLinearMap.uniformContinuous
        refine UniformContinuous.comp_tendstoUniformly hg ?_
        exact this

notation  A "**" T => T ∘L A
example (v : V) (φ : 𝓓 k Ω ) (T : 𝓓' k Ω ): (fderiv𝓓 v ** T) φ = T (fderiv𝓓 v φ) := by rfl



@[simp] def reflection  : 𝓓F k V →L[k] (𝓓F k V) := fromEndoOfV (reflection' k) (reflectionIsProper _)
postfix:200 "ʳ" => reflection
