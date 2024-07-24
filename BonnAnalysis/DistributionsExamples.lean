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
import BonnAnalysis.ConvolutionTendsToUniformly
import Mathlib

import Mathlib.Analysis.Convolution
--import Mathlib.Analysis.InnerProductSpace
-- import Mathlib.Order
-- noncomputable section
--open FourierTransform MeasureTheory Real


namespace MeasureTheory
open MeasureTheory
open scoped Pointwise
universe u v w
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
variable  {V : Type u}  [MeasurableSpace V] [NormedAddCommGroup V]  [NormedSpace k V]
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

variable {V : Type u} {k : Type v} [NontriviallyNormedField k]
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
  iteratedFDeriv k (l) (φ0.φ.comp (shift' k v)) (x) = iteratedFDeriv k l φ0 (x - v) := by

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
          let φ0' : V → k := (φ0.φ ).comp ((shift' k (- Φ 0)))
          have : φ0 ∘ Φ =  φ0' ∘ Φ.contLinear := by
            ext x ;  simp only [φ0',Function.comp_apply,
            shift', sub_neg_eq_add, ContinuousAffineMap.coe_mk, AffineMap.coe_mk,
            ContinuousAffineMap.coe_contLinear] ; congr ; apply affineAsUnderlyingLinearTransition
          rw [this]
          ext1 y
          rw [ContinuousLinearMap.iteratedFDeriv_comp_right (i:=l) (Φ.contLinear) ?_ _ (OrderTop.le_top _)]
          · have lol : ((iteratedFDeriv k l φ0' (Φ.contLinear x)).compContinuousLinearMap fun x ↦ Φ.contLinear) =
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
      use ψ ∘ Φ
      · exact ContDiff.comp ψ.φIsSmooth (ContinuousAffineMap.contDiff  Φ )
      · apply IsCompact.of_isClosed_subset ; swap
        exact isClosed_tsupport (ψ.φ ∘ Φ)
        swap
        · exact supportfromEndoOfV (k:=k)  Φ ψ
        · apply IsProperMap.isCompact_preimage
          apply (hΦ)
          exact (ψ.φHasCmpctSupport)
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

  have obs {φ : V → k} : tsupport (fun x => fderiv k φ x v) ⊆ tsupport (φ) := by -- ⊆ tsupport (fun x => fderiv k φ) :=
    trans ; swap
    · exact tsupport_fderiv_subset k (f:= φ)
    · apply tsupport_comp_subset rfl (g := fun f => f v)  (f:=fderiv k φ)
  let f : 𝓓 k Ω → 𝓓 k Ω := fun φ => by
    use fun x => fderiv k φ x v
    · have dfh : ContDiff k ⊤ (fun x => fderiv k φ.φ x) := (contDiff_top_iff_fderiv.mp (φ.φIsSmooth )).2

      have evvh : ContDiff k ⊤ (NormedSpace.inclusionInDoubleDual k V v) := by apply ContinuousLinearMap.contDiff

      apply ContDiff.comp  evvh dfh


    · apply IsCompact.of_isClosed_subset (φ.φHasCmpctSupport)
      exact isClosed_tsupport fun x ↦ (fderiv k φ.φ x) v
      exact obs
    ·
          trans
          · exact obs
          · exact φ.sprtinΩ
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
              · exact diffAt k Ω φ p
              · exact diffAt k Ω ψ p
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


-- notation:67 ψ "ʳ" => ψʳ


  --


--rw [Metric.tendstoUniformly_iff]
---------- the rest deals with real numbers
variable  (V : Type u) [MeasureSpace V] [NormedAddCommGroup V]  [NormedSpace ℝ V] [T2Space V]
  [MeasureSpace V] [OpensMeasurableSpace V] {Ω : Opens V} [OpensMeasurableSpace V]  [IsFiniteMeasureOnCompacts (volume (α := V))] --[IsFiniteMeasureOnCompacts (volume V)]


@[simp] def intSm (φ : V → 𝓓F ℝ V)  (hφ : HasCompactSupport (fun x y => φ y x)) : 𝓓F ℝ V := ⟨ fun y => ∫ x , φ x y , by sorry , by sorry , by sorry⟩
-- ContinuousLinearMap.integral_comp_comm PROBLEM: 𝓓F ℝ V is not NormedAddGroup so we cant apply
-- probably some smoothness condition on φ is missing anyway really Ccinfty(Ω × Ω ) needed?
lemma FcommWithIntegrals (φ : V → 𝓓F ℝ V)  (hφ : HasCompactSupport (fun x y => φ y x)) (T : 𝓓'F ℝ V) : T (intSm V φ hφ) =  ∫ x : V ,  T (φ x)  := by
  symm
  sorry




lemma convOfTestFunctionsExists {φ ψ : 𝓓F ℝ V} : ConvolutionExists φ.φ ψ.φ (ContinuousLinearMap.lsmul ℝ ℝ) :=
  convOfCtsCmpctSupportExists (ContDiff.continuous (𝕜:=ℝ ) (ψ.φIsSmooth)) ψ.φHasCmpctSupport

open MeasureSpace

variable {V : Type u}  [MeasureSpace V]
   [NormedAddCommGroup V]  [NormedSpace ℝ V] [ProperSpace V] [MeasureTheory.Measure.IsAddHaarMeasure (volume : Measure V)] [BorelSpace V] {Ω : Opens V} [T2Space V]  [SecondCountableTopology V] [LocallyCompactSpace V]






/-
The next two lemmas look similar and are proven similarly. If I have time I try to generalize.
-/
-- lemma zeroSeq'  {R : Type*} [AddCommGroup R] [TopologicalSpace R] [TopologicalAddGroup R] [SeminormedAddGroup R] [Module ℝ R]
--    {a : ℕ → R} {α : ℕ → R} {C : ℝ≥0}
--   (ha : ∀ n , ‖ a n‖ ≤ C * ‖ α n‖ )
--   (hα : ∀ ε > 0 , ∃ a, ∀ n ≥ a, ‖ α n‖ < ε) : Tendsto a atTop (𝓝 0) := by

lemma zeroSeq {a : ℕ → ℝ} {α : ℕ → ENNReal} {C : ℝ≥0}
  (ha : ∀ n , ‖ a n‖ ≤ (α n).toReal * C )
  (hα : ∀ ε > 0 , ∃ a, ∀ n ≥ a, (α n).toReal < ε) : Tendsto a atTop (𝓝 0) := by
      rw [← tendsto_sub_nhds_zero_iff]
      simp_rw [ NormedAddCommGroup.tendsto_nhds_zero, eventually_atTop ]
      intro ε hε

      by_cases h : C = 0
      · use 0 ; intro b hb ;
        apply LE.le.trans_lt
        · simp ; exact ha b
        · have : ‖(α b).toReal‖ * C   < ε := by
            rw [h] ;
            simp
            exact hε
          rw [show  ‖(α b).toReal‖ = (α b).toReal from NNReal.norm_eq _] at this
          exact this
      · let ε' : ℝ := ε / C
        -- have hε' : ε' > 0 ∧
        have hC : 0 < C := pos_iff_ne_zero.mpr h
        obtain ⟨ m , hm ⟩ :=  hα ε' (by apply (div_pos_iff_of_pos_right ?_).mpr ; exact hε ;   exact hC  )
        use m

        intro b hb
        specialize hm b hb
        apply LE.le.trans_lt
        · simp ; exact ha b
        · rw [show (ε = ε' * C ) from ?_]
          · apply (mul_lt_mul_right ?_ ).mpr

            exact hm
            exact hC
          · refine Eq.symm (IsUnit.div_mul_cancel ?q _)
            exact (Ne.isUnit (coe_ne_zero.mpr h))


lemma shouldExist  {E' : Type*} [NormedAddCommGroup E'] [NormedSpace ℝ E']
  {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
  (f : E' → E)  [MeasureSpace E'] (K : Set E') (hK1 : MeasurableSet K) (hK : support f ⊆ K)
  : ∫ (x : E' ) , f x = ∫ (x : E') in K , f x := by symm ; rw [← MeasureTheory.integral_indicator _] ; congr ; rw [Set.indicator_eq_self] ; exact hK ; exact hK1

lemma testFunctionMeasurable {φ : 𝓓 ℝ Ω} : AEStronglyMeasurable φ.φ volume := by apply Continuous.aestronglyMeasurable ; apply ContDiff.continuous (𝕜:=ℝ ) (φ.φIsSmooth)
@[simp] def Λ (f : LocallyIntegrableFunction V) : 𝓓' ℝ Ω := by
  have fIsIntegrableOnK {K : Set V} (hK : IsCompact K) := LocallyIntegrable.integrableOn_isCompact f.hf hK
  have fIsIntegrableOnK' {K : Set V} (hK : IsCompact K) : ∫⁻ (a : V) in K, ↑‖f.f a‖₊ ≠ ⊤ := by apply LT.lt.ne_top ; exact (fIsIntegrableOnK hK).2
  have integrable {ψ : 𝓓 ℝ Ω} : Integrable (fun v ↦ ψ v * f.f v) volume := by
          let K := tsupport ψ

          have hf : ((fun v ↦  ψ v  * f.f v  ) = fun v => ψ v *  K.indicator f.f v  ) := by
           have hsψ : support ψ ⊆ K := subset_tsupport ψ.φ
           nth_rw 2 [← Set.indicator_eq_self.mpr hsψ]
           rw [← Set.indicator_mul]
           refine Eq.symm ( Set.indicator_eq_self.mpr ?_)
           trans
           · refine Function.support_mul_subset_left _ _
           · exact hsψ
          rw [hf]
          apply MeasureTheory.Integrable.bdd_mul
          · have hK := ψ.φHasCmpctSupport ;
            rw [MeasureTheory.integrable_indicator_iff] ;
            apply fIsIntegrableOnK  ;
            · exact hK ;
            · apply IsCompact.measurableSet ;
              exact hK
          · exact testFunctionMeasurable (φ := ψ)

          apply testFunctionIsBnd

  apply mk ; swap
  · exact fun φ => ∫ v , φ v * f v
  · constructor
    · intro φ ψ ; rw [← integral_add] ;
      · congr ;
        ext v ;
        apply add_mul ;
      · apply integrable ;
      · apply integrable ;

    · intro c φ ; symm ; rw [← integral_smul] ; congr ; ext v ; simp ; rw [← mul_assoc] ; congr ;
    · constructor
      intro φ φ₀  hφ
      obtain ⟨ K , hK ⟩ := hφ.1


      have {a b : ℝ } : ENNReal.ofReal (‖ a‖ * ‖b‖) = ↑(‖a‖₊ * ‖b‖₊) := by
        calc
           ENNReal.ofReal (‖ a‖ * ‖b‖) = ENNReal.ofReal (‖ a * b‖) := by congr ; rw [← norm_mul]
           _ = ↑(‖ a * b‖₊)  := by exact ofReal_norm_eq_coe_nnnorm (a * b)
           _ = ↑(‖a‖₊ * ‖b‖₊) := by congr ; exact nnnorm_mul a b

      have mainArg : ∀ n ,
         ‖  (∫ (v : V), (φ n).φ v * f.f v)  - ∫ (v : V), φ₀.φ v * f.f v  ‖₊
        ≤  ENNReal.toReal (|| (φ n).φ - φ₀.φ ||_∞)  * ENNReal.toReal (∫⁻ (v : V) in K,   ‖ (f v) ‖₊ ) := by
        intro n

        have fIsMeasureable : AEMeasurable fun a ↦ ENNReal.ofNNReal ‖f.f a‖₊ := by
          refine AEMeasurable.ennnorm ?hf
          have : MeasureTheory.AEStronglyMeasurable f.f := by apply LocallyIntegrable.aestronglyMeasurable ; exact f.hf
          measurability


        have supportφ₀ := KcontainsSuppOfLimit ℝ Ω hφ hK
        have someArg : (support fun x => ((φ n).φ - φ₀.φ) x * f.f x ) ⊆ K := by
          rw [Function.support_mul ((φ n).φ - φ₀.φ) (f.f)]
          trans
          · exact inter_subset_left
          rw [← Set.union_self K]
          trans
          · apply Function.support_sub
          · apply Set.union_subset_union
            · trans ; exact subset_tsupport _ ; exact hK.2 n
            · trans ; exact subset_tsupport _ ; exact supportφ₀
        have someOtherArg : (∫⁻ (v : V) in K , ‖ ((φ n).φ -φ₀.φ) v ‖₊ * ‖ f.f v ‖₊  ).toReal  ≤
          (∫⁻ (v : V) in K , || ((φ n).φ -φ₀.φ) ||_∞ * ‖ f.f v ‖₊  ).toReal := by
          have : || (φ n).φ - φ₀.φ ||_∞ ≠ ⊤ := by apply LT.lt.ne_top ; apply LE.le.trans_lt ; apply MeasureTheory.snormEssSup_add_le ; apply WithTop.add_lt_top.mpr ; constructor ; exact EssSupTestFunction ℝ _ (φ n); exact EssSupTestFunction _ _ (-φ₀)
          apply ENNReal.toReal_mono ;
          · apply LT.lt.ne_top ; rw [MeasureTheory.lintegral_const_mul''] ; apply WithTop.mul_lt_top ; exact this ; exact fIsIntegrableOnK' hK.1 ; apply AEMeasurable.restrict ;  exact fIsMeasureable
          · apply MeasureTheory.lintegral_mono_ae ;
            --rw
            have {a : V}  (ha : ‖ ((φ n).φ -φ₀.φ) a‖₊   ≤   || ((φ n).φ -φ₀.φ) ||_∞ ) :
             ↑‖((φ n).φ - φ₀.φ) a‖₊ *  ↑‖f.f a‖₊  ≤ || (φ n).φ - φ₀.φ ||_∞ * ↑‖f.f a‖₊   := by
              calc
              _ = ENNReal.ofNNReal (‖((φ n).φ - φ₀.φ) a‖₊ * ‖f.f a‖₊ ) := by rfl
              _ ≤ ENNReal.ofNNReal ( || ((φ n).φ -φ₀.φ) ||_∞.toNNReal * ‖f.f a‖₊ ) := by apply ENNReal.coe_mono ; apply mul_le_mul_right'  ; refine ENNReal.toNNReal_mono ?_ ha ; exact this
              _ = ( (ENNReal.ofNNReal  || ((φ n).φ -φ₀.φ) ||_∞.toNNReal) * ‖f.f a‖₊ ) := by apply ENNReal.coe_mul
              _ = _ := by congr; apply ENNReal.coe_toNNReal ; exact this
            rw [Filter.eventually_iff]
            apply sets_of_superset
            · apply MeasureTheory.ae_le_snormEssSup (f:=((φ n).φ -φ₀.φ))
            · intro x hx
              apply this
              trans
              · exact hx
              · apply MeasureTheory.snormEssSup_mono_measure
                apply Measure.absolutelyContinuous_of_le
                trans ; swap
                · apply le_of_eq
                  have : volume (α := V) = volume.restrict univ := Eq.symm Measure.restrict_univ
                  rw [this]
                · apply Measure.restrict_mono
                  exact fun _ _ ↦ trivial
                  exact le_of_eq rfl
        calc
        ‖  (∫ (v : V), (φ n).φ v *  f.f v) - ∫ (v : V), φ₀.φ v * f.f v‖
          = ‖  ∫ (v : V) , (φ n).φ v * f.f v  - φ₀.φ v * f.f v‖  := by congr ; rw [← MeasureTheory.integral_sub] ; exact integrable ; exact integrable
        _ = ‖  ∫ (v : V) , ((φ n).φ v -φ₀.φ v) * f.f v‖ := by congr ; ext1 v ; symm ; exact (sub_smul ((φ n).φ v) (φ₀.φ v) (f.f v) )
        _ = ‖  ∫ (v : V) in K , (((φ n).φ -φ₀.φ) * f.f) v‖ := by apply congrArg ; apply shouldExist (fun v => ((φ n).φ -φ₀.φ) v * f.f v ) K ; exact IsCompact.measurableSet hK.1 ; exact someArg
        _ ≤ (∫⁻ (v : V) in K , ENNReal.ofReal ‖ (((φ n).φ -φ₀.φ) v) * f.f v‖ ).toReal   := by apply MeasureTheory.norm_integral_le_lintegral_norm (((φ n).φ -φ₀.φ) * f.f )
        _ = (∫⁻ (v : V) in K , ‖ ((φ n).φ -φ₀.φ) v ‖₊ * ‖ f.f v ‖₊ ).toReal   := by  congr ; ext v ; simp_rw [norm_mul] ; trans ; swap ;  apply ENNReal.coe_mul ; exact this
        _ ≤ (∫⁻ (v : V) in K ,  || ((φ n).φ -φ₀.φ) ||_∞ * ‖ f.f v ‖₊).toReal   := by exact someOtherArg
        _ =  ((|| ((φ n).φ -φ₀.φ) ||_∞) * (∫⁻ (v : V) in K , ‖ f.f v ‖₊ )).toReal := by congr ;  apply MeasureTheory.lintegral_const_mul''  (|| ((φ n).φ -φ₀.φ) ||_∞) ; apply AEMeasurable.restrict ; exact fIsMeasureable
        _ = (|| ((φ n).φ -φ₀.φ) ||_∞).toReal * (∫⁻ (v : V) in K , ‖ f.f v ‖₊ ).toReal   := by rw [ENNReal.toReal_mul]

      have : TendstoUniformly (fun n => (φ n) ) φ₀ atTop := by apply (zeroCase _).mp ; exact hφ.2 0
        --
      let C : ℝ≥0 := ENNReal.toNNReal (∫⁻ (v : V) in K,   ‖ (f v) ‖₊ )
      rw [← tendsto_sub_nhds_zero_iff]
      exact zeroSeq mainArg (EssSupNormSub this)


open Convolution

@[simp] def shift (x : V) : 𝓓F ℝ V →L[ℝ] 𝓓F ℝ V := fromEndoOfV (shift' ℝ x) (shiftIsProper ℝ x)
--lemma tsupportShift {v : V} {ψ : 𝓓F ℝ V} : tsupport (shift v ψ) ⊆ {x - v | x : tsupport ψ } := by
theorem integral_congr {f g : V → ℝ} (p : ∀ x , f x = g x) : ∫ x , f x = ∫ x , g x := by congr ; ext x ; exact p x

@[simp] def convWith  ( φ : 𝓓F ℝ V) : (𝓓F ℝ V) →L[ℝ] 𝓓F ℝ V := by
  apply mk ℝ  ; swap
  intro ψ
  use  φ ⋆ ψ
  --rw [← contDiffOn_univ] ;
  · apply HasCompactSupport.contDiff_convolution_right
    · exact ψ.φHasCmpctSupport
    · exact (testFunctionIsLocallyIntegrable V φ)
    · exact ψ.φIsSmooth
  · apply HasCompactSupport.convolution
    · exact φ.φHasCmpctSupport
    · exact ψ.φHasCmpctSupport
  · exact fun _ _ ↦ trivial
  · constructor
    · intro ψ₁ ψ₂ ; ext z ; simp ; apply ConvolutionExistsAt.distrib_add ; exact convOfTestFunctionsExists z ; exact convOfTestFunctionsExists z --help
    · intro c ψ ; ext z ; simp ; exact congrFun (convolution_smul (𝕜 := ℝ ) (F:= ℝ ) (G:= V) (f:=φ.φ) (g:= ψ.φ) ) z
    · constructor
      intro ψ ψ0 hψ
      apply tendsTo𝓝
      constructor
      · obtain ⟨ K , hK⟩ := hψ.1
        use tsupport (φ) + K
        constructor
        · apply add_compact_subsets
          exact φ.φHasCmpctSupport
          exact hK.1
        -- · apply IsCompact.union
        --   exact φ.φHasCmpctSupport
        --   exact hK.1
        · intro n
          have : tsupport (φ.φ ⋆ (ψ n).φ) ⊆ tsupport φ.φ + tsupport (ψ n).φ := by
            apply tsupport_convolution_subset
            exact φ.φHasCmpctSupport
            exact (ψ n).φHasCmpctSupport
          trans
          · exact this
          · apply add_subset_add_left
            exact hK.2 n



      · intro l
        induction' l with l hl -- ψ ψ0 hψ --
        · simp
          apply (zeroCase _).mpr
          exact ConvWithIsUniformContinuous ((zeroCase ℝ ).mp (hψ.2 0))
        · apply iteratedDerivConv
          exact ((zeroCase ℝ ).mp (hψ.2 0))


notation:67 φ " 𝓓⋆ " ψ => convWith φ ψ -- convolution𝓓Mult (tF2 φ ψ)
--@[simp] def convWith (φ : 𝓓 ℝ Ω ) : 𝓓 ℝ Ω →L[ℝ] 𝓓 ℝ Ω := ContinuousMultilinearMap.toContinuousLinearMap convolution𝓓Mult (tF2 φ 0) 1

open ContinuousLinearMap

notation:67 T " °⋆ " φ  =>  convWith (φʳ) ** T
example  (φ : 𝓓F ℝ V ) (T : 𝓓' ℝ (Full V) ) : ∀ ψ, (T °⋆ φ) ψ = T ( φʳ 𝓓⋆ ψ) := fun _ => rfl
lemma convAsLambda (φ ψ : 𝓓F ℝ V) : (φ 𝓓⋆ ψ) = fun x => Λ (φ : LocallyIntegrableFunction V) (shift  x (ψʳ)) := by
  simp
  unfold convolution
  simp_rw [mul_comm]


  ext x ;
  simp only [ContinuousLinearMap.lsmul_apply, smul_eq_mul]
  congr
  ext v
  rw [neg_add_eq_sub]




-- def smoothFuncForConv (ψ : 𝓓F ℝ V ) :  (𝓓F ℝ V) :=
open Measure.IsAddHaarMeasure
-- example [MeasureTheory.Measure.IsAddHaarMeasure (volume (α := V))]: Measure.IsNegInvariant (volume (α := V)) := by exact?
lemma shift_comm_fderiv {ψ : 𝓓F ℝ V} {v : V}  {l : ℕ} :
   iteratedFDeriv ℝ l (shift v ψ) =  (iteratedFDeriv ℝ l ψ) ∘ (shift' (k := ℝ) v)  := by
    trans iteratedFDeriv ℝ l (ψ ∘ shift' ℝ v)
    · rfl
    · ext1 x ; apply ContinuousAffineMap.iteratedFDeriv_comp_right
theorem  shiftIsContinuous {ζ : 𝓓F ℝ V} : Continuous (fun v => shift v ζ) := by
  apply SeqContinuous.continuous
  intro x x0 hx
  apply tendsTo𝓝
  constructor
  have : ∃ K' : Set V  , IsCompact K' ∧ ∀ n , x n ∈ K' := by
    have :∃ R > 0, ∀ (m n : ℕ), dist (x m) (x n) < R := by  apply cauchySeq_bdd ; apply Filter.Tendsto.cauchySeq ; exact hx
    obtain ⟨ r , hr⟩ := this
    use Metric.closedBall (x 0) r
    constructor
    · exact isCompact_closedBall (x 0) r
    · intro n  ; simp ; apply le_of_lt ; apply hr.2


  obtain ⟨ K' , hK' ⟩ := this
  use K' + tsupport ζ
  constructor
  apply add_compact_subsets ; exact hK'.1 ; exact ζ.φHasCmpctSupport
  intro n
  trans
  · exact supportfromEndoOfV (Φ := shift' ℝ (x n)) ζ
  · rw [show ⇑(shift' ℝ (x n)) ⁻¹' tsupport ζ.φ = {x n} + tsupport ζ.φ  from ?_]
    apply Set.add_subset_add_right
    refine singleton_subset_iff.mpr ?_
    exact hK'.2 n
    ext y ;
    rw [Set.singleton_add]
    constructor
    · intro hy
      simp at hy
      simp
      rw [neg_add_eq_sub]
      exact hy
    · intro hy
      obtain ⟨ z , hz ⟩ := hy
      simp only [shift', ContinuousAffineMap.coe_mk, AffineMap.coe_mk, mem_preimage]
      rw [show y - x n = z from ?_]
      exact hz.1
      rw [← hz.2]
      simp only [add_sub_cancel_left]
  intro l
  have : (fun n ↦ iteratedFDeriv ℝ l (((fun v ↦  (shift v ζ) ) ∘ x) n).φ)  =
    (fun n ↦ iteratedFDeriv ℝ l  ζ ∘ shift' ℝ (x n))
    := by
      trans (fun n ↦ iteratedFDeriv ℝ l ( shift (x n) ζ ))
      · rfl
      · ext1 n ; rw [shift_comm_fderiv]
  rw [this]
  rw [shift_comm_fderiv]


  apply UniformContinuous.comp_tendstoUniformly
  · apply HasCompactSupport.uniformContinuous_of_continuous ;
    · apply HasCompactSupport.iteratedFDeriv
      exact ζ.φHasCmpctSupport
    · apply ContDiff.continuous_iteratedFDeriv ( OrderTop.le_top _) (ζ.φIsSmooth)

  · rw [Metric.tendstoUniformly_iff]
    have {x_1 } {b} : dist (x_1 - x0 + x b) x_1 = ‖ (x b) - x0‖ := by
      rw [dist_eq_norm] ; apply congrArg ; rw[ sub_eq_neg_add ,
      show -x_1 + (x_1 - x0 + x b) = (-x_1 + x_1) + (- x0 + x b) from ?_ , ← sub_eq_neg_add,← sub_eq_neg_add ] ;
      trans 0 + (x b - x0) ; swap
      · rw [zero_add] ;   -- ,  add_assoc , ← add_ssoc ] ;
      · congr ; exact sub_eq_zero_of_eq rfl
      rw [add_assoc]
      apply congrArg
      rw [← add_assoc]
      rw [sub_eq_add_neg x_1 x0]
    simp
    simp_rw [this]
    have : ∀ (ε : ℝ), 0 < ε → ∃ a, ∀ (b : ℕ), a ≤ b → ‖(x b) - x0‖ < ε := by
      rw [← tendsto_sub_nhds_zero_iff] at hx
      simp_rw [ NormedAddCommGroup.tendsto_nhds_zero, eventually_atTop ] at hx
      exact hx
    intro ε hε
    obtain ⟨ a , ha ⟩ := this ε hε
    use a
    intro b hb _
    exact ha b hb




def convolutionAsFunction (T : 𝓓'F ℝ V ) (ψ : 𝓓F ℝ V )  :  LocallyIntegrableFunction V := by
  let ψ'f := fun x =>T (shift x (ψʳ))
  use ψ'f
  apply Continuous.locallyIntegrable ;
  rw [show ψ'f = T ∘ (fun v => shift  v (ψʳ)) from rfl] ;
  apply Continuous.comp T.cont ;
  apply shiftIsContinuous
notation T " *f " ψ => convolutionAsFunction T ψ

theorem convolutionProp  (ψ : 𝓓F ℝ V ) (T : 𝓓'F ℝ V ) : (T °⋆ ψ) = Λ (T *f ψ) := by
    ext φ
    symm
    trans
    have : Λ (T *f ψ) φ = ∫ x , φ x  * T (shift x (ψʳ))  := by
        congr ;
    exact this
    trans
    ·   apply integral_congr
        intro x
        symm
        exact T.map_smul (φ.φ x) _

    ·   let biφ : V → 𝓓F ℝ V := fun x => φ x • (shift x (ψʳ))

        have biφcalc {x y : V} := calc
              biφ x y = φ x * ψ (- (y - x)) := by rfl
              _ = φ x * (ψ (x-y)) := by rw [neg_sub ]
        have sub_compact : IsCompact (tsupport φ.φ - tsupport ψ.φ) :=
             sub_compact_subsets (φ.φHasCmpctSupport) (ψ.φHasCmpctSupport)
        have hbiφ : HasCompactSupport (fun x y => biφ y x) := by
          apply IsCompact.of_isClosed_subset
          exact sub_compact
          apply isClosed_tsupport
          have : (fun y x => biφ x y) = (fun y  => φ.φ * (shift y ψ ) ) := by ext y x ; exact biφcalc
          simp_rw [this]
          apply closure_minimal ; swap
          · apply IsCompact.isClosed ; exact sub_compact
          ·   trans (support φ) - (support ψ) ; swap
              · apply sub_subset_sub
                · apply subset_tsupport
                · apply subset_tsupport
              · intro y hy
                simp only [instAddCommGroup𝓓, fromEndoOfV, mk, ContinuousLinearMap.coe_mk',
                  LinearMap.coe_mk, AddHom.coe_mk, mem_support, ne_eq] at hy
                have hy := Function.support_nonempty_iff (f:= φ.φ * ((shift y ψ).φ)).mpr hy
                obtain ⟨ x , hx ⟩ := hy
                have hx1 : x ∈ support φ.φ := by apply support_mul_subset_left ; exact hx
                have hx2 : x ∈ support (shift y ψ) := by apply support_mul_subset_right ; exact hx --
                constructor
                constructor
                exact hx1
                use x - y
                constructor
                · exact hx2
                · simp only [sub_sub_cancel]
        trans  ;
        · symm ; exact FcommWithIntegrals V biφ hbiφ T
        · simp
          congr
          ext y
          trans ; swap
          · exact (congrFun (convAsLambda ( ψʳ) (φ )) y).symm
          · simp
            symm
            rw [← MeasureTheory.integral_sub_left_eq_self _ _ y ]
            congr
            ext x
            simp only [neg_sub, sub_add_cancel]
            symm
            exact biφcalc
theorem convolution𝓓'IsSmooth (ψ : 𝓓F ℝ V ) (T : 𝓓'F ℝ V ) : ContDiff ℝ ⊤ (T *f ψ) := by
  -- have SeqContℕψ'  : Tendsto (ψ'f ∘ x) atTop (𝓝 (ψ'f x0)) := by
  --     apply (SeqContinuous'OfContinuous ℝ T).seqCont



  /- Idea how to get smoothness from here:
  For every ψ we find ψ' s.th. As T °⋆ ψ = Λ ψ'  , we find a function ∂ψ' such that T °⋆ ∂ ψ = Λ ∂ψ'
  One can show Then
  ∂ Λ ψ' = ∂ (T °* ψ) = T °⋆ ∂ ψ = Λ ∂ψ'
  If the weak derivative of a continuous function is continuous then the function was cont diff.
  -/
  --sorry --help


  · let ζ := ψʳ

    sorry
-- #lint
