-- Terms are intrinsically typed.
-- Terms are the typing derivations of untyped terms (which are not shown).

-- For greek letters, type \ G <letter>.

open import Types

-- Syntax.

mutual

  infixl 10 _[_]

  -----------------------------------------
  -- Well-typed terms.
  -----------------------------------------

  data Tm : (Γ : Cxt) (a : Ty) → Set where

    -- The last variable.

    var₀ : ∀{Γ a}
      → Tm (Γ , a) a

    -- λ-abstraction.

    abs : ∀{Γ a b}
      (t : Tm (Γ , a) b)
      → Tm Γ (a ⇒ b)

    -- Application.

    app : ∀{Γ a b}
      (t : Tm Γ (a ⇒ b))
      (u : Tm Γ a)
      → Tm Γ b

    -- Explicit substitution.

    _[_] : ∀{Γ Δ a}
      (t : Tm Γ a)
      (s : Sub Δ Γ)
      → Tm Δ a

  -----------------------------------------
  -- Well-typed substitutions.
  -----------------------------------------

  infixl 2 _,_
  infixl 4 _∘_

  data Sub : (Γ Δ : Cxt) → Set where

    -- The empty substitution.

    ε : ∀{Γ}
      → Sub Γ ε

    -- Substitution extension.

    _,_ : ∀{Γ Δ a}
      (s : Sub Γ Δ)
      (t : Tm Γ a)
      → Sub Γ (Δ , a)

    -- The weakening substitution.

    wk : ∀{Γ a}
      → Sub (Γ , a) Γ

    -- The identity substitution.

    id : ∀{Γ}
      → Sub Γ Γ

    -- Substitution composition.

    _∘_ : ∀{Γ Δ Φ}
      (r : Sub Δ Φ)
      (s : Sub Γ Δ)
      → Sub Γ Φ

-- Note: identity and composition are definable by induction on contexts.
--
-- id {ε}     = ε
-- id {Γ , a} = wk , var₀
--
-- _∘wk : ∀ {Δ Γ a} → Sub Δ Γ → Sub (Δ , a) Γ
-- _∘wk {Γ = ε}     _       = ε
-- _∘wk {Γ = _ , _} (r , t) = r ∘wk , t [ wk ]
-- _∘wk {Γ = _ , _} wk      = wk ∘wk ∘wk , var₀ [ wk ] [ wk ]
--
-- wk∘_ : ∀ {Δ Γ a} → Sub Δ (Γ , a) → Sub Δ Γ
-- wk∘_ (r , _) = r
-- wk∘_ wk      = wk ∘wk
--
-- _∘_ {Φ = ε}     _ _ = ε
-- _∘_ {Φ = _ , _} r s = wk∘ r ∘ s ,  var₀ [ r ] [ s ]

-- Equational theory.

mutual

  infix 0 _≅_ _≈_  -- \cong \approx

  -----------------------------------------
  -- Equal terms.
  -----------------------------------------

  data _≅_ : ∀ {Γ a} (t t' : Tm Γ a) → Set where

    -- β-equality.

    teq-beta : ∀{Γ a b} {t : Tm (Γ , a) b} {u : Tm Γ a}
      → app (abs t) u ≅ t [ id , u ]

    -- η-equality.

    teq-eta : ∀{Γ a b} {t : Tm Γ (a ⇒ b)}
      → t ≅ abs (app (t [ wk ]) var₀)

    -- β-equality law for substitutions.

    teq-var-s : ∀{Γ Δ a} {s : Sub Γ Δ} {u : Tm Γ a}
      → var₀ [ s , u ] ≅ u

    -- Propagation of substitutions.

    teq-abs-s : ∀{Γ Δ a b} {s : Sub Γ Δ} {t : Tm (Δ , a) b}
      → (abs t) [ s ] ≅ abs (t [ s ∘ wk , var₀ ])

    teq-app-s : ∀{Γ Δ a b} {s : Sub Γ Δ} {t : Tm Δ (a ⇒ b)} {u : Tm Δ a}
      → (app t u) [ s ] ≅ app (t [ s ]) (u [ s ])

    teq-sub-s : ∀{Γ Δ Φ a} {s : Sub Γ Δ} {r : Sub Δ Φ} {t : Tm Φ a}
      → (t [ r ]) [ s ] ≅ t [ r ∘ s ]

    -- Congruence closure.

    teq-var : ∀{Γ a}
      → var₀ ≅ var₀ {Γ} {a}

    teq-abs : ∀{Γ a b} {t t' : Tm (Γ , a) b}
      → t ≅ t'
      → abs t ≅ abs t'

    teq-app : ∀{Γ a b} {t t' : Tm Γ (a ⇒ b)} {u u' : Tm Γ a}
      → t ≅ t'
      → u ≅ u'
      → app t u ≅ app t' u'

    teq-sub : ∀{Γ Δ a} {s s' : Sub Γ Δ} {t t' : Tm Δ a}
      → t ≅ t'
      → s ≈ s'
      → t [ s ] ≅ t' [ s' ]

    -- Equivalence laws (reflexivity is admissible).

    teq-sym : ∀{Γ a} {t t' : Tm Γ a}
      → t' ≅ t
      → t ≅ t'

    teq-trans : ∀{Γ a} {t u v : Tm Γ a}
      → t ≅ u
      → u ≅ v
      → t ≅ v

  -----------------------------------------
  -- Equal substitutions.
  -----------------------------------------

  data _≈_ : ∀{Γ Δ} (s s' : Sub Γ Δ) → Set where

     -- Category laws.

     seq-id-l : ∀{Γ Δ} {s : Sub Γ Δ}
       → id ∘ s ≈ s

     seq-id-r : ∀{Γ Δ} {s : Sub Γ Δ}
       → s ∘ id ≈ s

     seq-assoc : ∀{Γ Δ Φ Ψ} {s₁ : Sub Φ Ψ} {s₂ : Sub Δ Φ} {s₃ : Sub Γ Δ}
       → (s₁ ∘ s₂) ∘ s₃ ≈ s₁ ∘ (s₂ ∘ s₃)

     -- β-equality for substitutions.

     seq-wk-pair : ∀{Γ Δ a} {s : Sub Γ Δ} {u : Tm Γ a}
       → wk ∘ (s , u) ≈ s

     -- η-equality.

     seq-eta-eps : ∀{Γ} {s s' : Sub Γ ε}
       → s ≈ s'

     seq-eta-pair : ∀{Γ a}
       → id {Γ , a} ≈ (wk , var₀)

     -- Propagation of substitutions.

     seq-pair-comp : ∀{Γ Δ Φ a} {s : Sub Γ Δ} {r : Sub Δ Φ} {u : Tm Δ a}
       → (r , u) ∘ s ≈ (r ∘ s , u [ s ])

     -- Congruence closure.

     seq-id : ∀{Γ}
       → id ≈ id {Γ}

     seq-comp : ∀{Γ Δ Φ} {r r' : Sub Δ Φ} {s s' : Sub Γ Δ}
       → r ≈ r'
       → s ≈ s'
       → r ∘ s ≈ r' ∘ s'

     seq-wk : ∀{Γ a}
       → wk ≈ wk {Γ} {a}

     seq-pair : ∀{Γ Δ a} {s s' : Sub Γ Δ} {u u' : Tm Γ a}
       → s ≈ s'
       → u ≅ u'
       → (s , u) ≈ (s' , u')

     -- Equivalence laws (reflexivity is admissible).

     seq-sym : ∀{Γ Δ} {s s' : Sub Γ Δ}
       → s' ≈ s
       → s ≈ s'

     seq-trans : ∀{Γ Δ} {s s' s'' : Sub Γ Δ}
       → s ≈ s'
       → s' ≈ s''
       → s ≈ s''



mutual

  -- We can abuse teq-var-s to prove reflexivity.

  teq-refl : ∀{Γ a} (t : Tm Γ a) → t ≅ t
  teq-refl {Γ} t = teq-trans (teq-sym (teq-var-s {_} {Γ} {_} {id})) teq-var-s

  -- We can abuse the identity laws to prove reflexivity.

  seq-refl : ∀{Γ Δ} (s : Sub Γ Δ) → s ≈ s
  seq-refl t = seq-trans (seq-sym seq-id-l) seq-id-l


------------------------------------------------------------------------
-- A translation of the simply-typed lambda calculus to the internal
-- language of CCCs.

open import CCCInternalLanguage
import Relation.Binary.Reasoning.Setoid as EqR

⟦_⟧ : Cxt → Ty
⟦ ε ⟧     = 𝟙
⟦ Γ , a ⟧ = ⟦ Γ ⟧ * a

mutual

  Tm⟦_⟧ : ∀ {Γ a} → Tm Γ a → Hom ⟦ Γ ⟧ a
  Tm⟦ var₀     ⟧ = snd
  Tm⟦ abs t    ⟧ = curry Tm⟦ t ⟧
  Tm⟦ app t t' ⟧ = apply ∘ pair Tm⟦ t ⟧ Tm⟦ t' ⟧
  Tm⟦ t [ s ]  ⟧ = Tm⟦ t ⟧ ∘ Sub⟦ s ⟧

  Sub⟦_⟧ : ∀ {Γ Δ} → Sub Γ Δ → Hom ⟦ Γ ⟧ ⟦ Δ ⟧
  Sub⟦ ε      ⟧ = unit
  Sub⟦ s , t  ⟧ = pair Sub⟦ s ⟧ Tm⟦ t ⟧
  Sub⟦ wk     ⟧ = fst
  Sub⟦ id     ⟧ = id
  Sub⟦ s ∘ s' ⟧ = Sub⟦ s ⟧ ∘ Sub⟦ s' ⟧

mutual

  Tm⟪_⟫ : ∀ {Γ a} {t t' : Tm Γ a} → t ≅ t' → Tm⟦ t ⟧ ~ Tm⟦ t' ⟧
  Tm⟪ teq-beta       ⟫ = beta _ _
  Tm⟪ teq-eta        ⟫ = eq-sym (curry-apply' _)
  Tm⟪ teq-var-s      ⟫ = snd-pair
  Tm⟪ teq-abs-s      ⟫ = curry-comp
  Tm⟪ teq-app-s      ⟫ = eq-trans assoc (eq-comp eq-refl pair-comp)
  Tm⟪ teq-sub-s      ⟫ = assoc
  Tm⟪ teq-var        ⟫ = eq-refl
  Tm⟪ teq-abs e      ⟫ = eq-curry Tm⟪ e ⟫
  Tm⟪ teq-app e e'   ⟫ = eq-comp eq-refl (eq-pair Tm⟪ e ⟫ Tm⟪ e' ⟫)
  Tm⟪ teq-sub e e'   ⟫ = eq-comp Tm⟪ e ⟫ Sub⟪ e' ⟫
  Tm⟪ teq-sym e      ⟫ = eq-sym Tm⟪ e ⟫
  Tm⟪ teq-trans e e' ⟫ = eq-trans Tm⟪ e ⟫ Tm⟪ e' ⟫

  Sub⟪_⟫ : ∀ {Γ Δ} {s s' : Sub Γ Δ} → s ≈ s' → Sub⟦ s ⟧ ~ Sub⟦ s' ⟧
  Sub⟪ seq-id-l       ⟫ = id-l
  Sub⟪ seq-id-r       ⟫ = id-r
  Sub⟪ seq-assoc      ⟫ = assoc
  Sub⟪ seq-wk-pair    ⟫ = fst-pair
  Sub⟪ seq-eta-eps    ⟫ = eq-trans unit (eq-sym unit)
  Sub⟪ seq-eta-pair   ⟫ = id-pair
  Sub⟪ seq-pair-comp  ⟫ = pair-comp
  Sub⟪ seq-id         ⟫ = eq-refl
  Sub⟪ seq-comp e e'  ⟫ = eq-comp Sub⟪ e ⟫ Sub⟪ e' ⟫
  Sub⟪ seq-wk         ⟫ = eq-refl
  Sub⟪ seq-pair e e'  ⟫ = eq-pair Sub⟪ e ⟫ Tm⟪ e' ⟫
  Sub⟪ seq-sym e      ⟫ = eq-sym Sub⟪ e ⟫
  Sub⟪ seq-trans e e' ⟫ = eq-trans Sub⟪ e ⟫ Sub⟪ e' ⟫
