/-
Copyright (c) 2021 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro
-/
import Mathport.Syntax.Translate.Tactic.Basic

open Lean
open Lean.Elab.Tactic (Location)

namespace Mathport.Translate.Tactic
open AST3 Parser

-- # tactic.doc_commands

@[trUserCmd «copy_doc_string»] def trCopyDocString : TacM Syntax := do
  let (fr, to_) ← parse $ do (← ident, ← tk "->" *> ident*)
  `(command| copy_doc_string $(← mkIdentI fr) → $(← liftM $ to_.mapM mkIdentI)*)

@[trUserCmd «library_note»] def trLibraryNote (doc : Option String) : TacM Syntax := do
  let Expr.string s ← parse pExpr | warn! "unsupported: weird string"
  `(command| $(trDocComment doc.get!):docComment library_note $(Syntax.mkStrLit s))

@[trUserCmd «add_tactic_doc»] def trAddTacticDoc (doc : Option String) : TacM Syntax := do
  `(command| $[$(doc.map trDocComment)]? add_tactic_doc $(← trExpr (← parse pExpr)))

@[trUserCmd «add_decl_doc»] def trAddDeclDoc (doc : Option String) : TacM Syntax := do
  `(command| $(trDocComment doc.get!):docComment add_decl_doc $(← mkIdentI (← parse ident)))