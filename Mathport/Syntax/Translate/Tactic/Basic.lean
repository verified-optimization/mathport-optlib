/-
Copyright (c) 2021 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro
-/
import Mathport.Syntax.Translate.Basic
import Mathport.Syntax.Translate.Parser

open Lean
open Lean.Elab.Tactic (Location)

namespace Mathport
namespace Translate

open AST3 Parser

namespace Tactic

structure Context where
  args : Array (Spanned Param)

structure State where
  pos : Nat := 0

abbrev TacM := ReaderT Context $ StateT State M

def TacM.run (m : TacM α) (args : Array (Spanned Param)) : M α := do
  let (a, ⟨n⟩) ← (m ⟨args⟩).run {}
  unless args.size = n do throw! "unsupported: too many args"
  a

def next? : TacM (Option Param) := do
  let args := (← read).args
  let i := (← get).pos
  if h : i < args.size then
    modify fun s => { s with pos := i+1 }
    (args.get ⟨i, h⟩).kind
  else none

def next! : TacM Param := do
  match ← next? with | some p => p | none => throw! "missing argument"

def parse (p : Parser.ParserM α) : TacM α := do
  let Param.parse _ args ← next! | throw! "expecting parse arg"
  match p ⟨(← readThe Translate.Context).commands, args⟩ |>.run' 0 with
  | none => throw! "parse error"
  | some a => a

def expr? : TacM (Option AST3.Expr) := do
  match ← next? with
  | none => none
  | some (Param.expr e) => some e.kind
  | _ => throw! "parse error"

def expr! : TacM AST3.Expr := do
  match ← expr? with | some p => p | none => throw! "missing argument"

def itactic : TacM AST3.Block := do
  let Param.block bl ← next! | throw! "expecting tactic arg"
  bl

def withNoMods (tac : TacM Syntax) : Modifiers → TacM Syntax
  | #[] => tac
  | _ => throw! "expecting no modifiers"

scoped instance : Coe (TacM Syntax) (Modifiers → TacM Syntax) := ⟨withNoMods⟩

def withDocString (tac : Option String → TacM Syntax) : Modifiers → TacM Syntax
  | #[] => tac none
  | #[⟨_, _, Modifier.doc s⟩] => tac (some s)
  | _ => throw! "unsupported modifiers in user command"

scoped instance : Coe (Option String → TacM Syntax) (Modifiers → TacM Syntax) := ⟨withDocString⟩

abbrev NameExt := SimplePersistentEnvExtension (Name × Name) (Array (Name × Name))

private def mkExt (name attr : Name) (descr : String) : IO NameExt := do
  let ext ← registerSimplePersistentEnvExtension {
    name
    addEntryFn := Array.push
    addImportedFn := fun es => es.foldl (·++·) #[]
  }
  registerBuiltinAttribute {
    name := attr
    descr
    add := fun declName stx attrKind => modifyEnv fun env =>
      stx[1].getArgs.foldl (init := env) fun env stx =>
        ext.addEntry env (stx.getId, declName)
  }
  ext

private def mkElab (ext : NameExt) (ty : Lean.Expr) : Elab.Term.TermElabM Lean.Expr := do
  let stx ← (ext.getState (← getEnv)).mapM fun (n3, n4) =>
    `(($(Syntax.mkNameLit s!"`{n3}"):nameLit, $(mkIdent n4):ident))
  Elab.Term.elabTerm (← `(#[$stx,*])) (some ty)

syntax (name := trTactic) "trTactic " ident+ : attr
syntax (name := trUserNota) "trUserNota " ident+ : attr
syntax (name := trUserAttr) "trUserAttr " ident+ : attr
syntax (name := trUserCmd) "trUserCmd " ident+ : attr

initialize trTacExtension : NameExt ←
  mkExt `Mathport.Translate.Tactic.trTacExtension `trTactic
    (descr := "lean 3 → 4 tactic translation")
initialize trUserNotaExtension : NameExt ←
  mkExt `Mathport.Translate.Tactic.trUserNotaExtension `trUserNota
    (descr := "lean 3 → 4 user notation translation")
initialize trUserAttrExtension : NameExt ←
  mkExt `Mathport.Translate.Tactic.trUserAttrExtension `trUserAttr
    (descr := "lean 3 → 4 user attribute translation")
initialize trUserCmdExtension : NameExt ←
  mkExt `Mathport.Translate.Tactic.trUserCmdExtension `trUserCmd
    (descr := "lean 3 → 4 user attribute translation")

elab "trTactics!" : term <= ty => mkElab trTacExtension ty
elab "trUserNotas!" : term <= ty => mkElab trUserNotaExtension ty
elab "trUserAttrs!" : term <= ty => mkElab trUserAttrExtension ty
elab "trUserCmds!" : term <= ty => mkElab trUserCmdExtension ty
