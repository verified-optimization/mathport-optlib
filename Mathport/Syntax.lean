/-
Copyright (c) 2021 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro, Daniel Selsam
-/
import Lean
import Mathport.Util.System
import Mathport.Util.Import
import Mathport.Util.Parse
import Mathport.Bridge.Path
import Mathport.Bridge.RenameExt
import Mathport.Bridge.Config
import Mathport.Syntax.AST3
import Mathport.Syntax.Data4
import Mathport.Syntax.Parse
import Mathport.Syntax.Translate

namespace Mathport

open Lean Lean.Elab.Command
open Syntax

def synport1 (config : Config) (path : Path) : CommandElabM Unit := do
  let pcfg := config.pathConfig
  let ast3 ← parseAST3 $ path.toLean3 pcfg ".ast.json"
  let ⟨fmt, _⟩ ← AST3toData4 ast3 pcfg
  IO.FS.writeFile (path.toLean4 pcfg "Syn.lean") (toString fmt)

open Lean Lean.Elab Lean.Elab.Term Lean.Elab.Tactic
open Lean.Parser Lean.PrettyPrinter

-- #eval show CoreM Unit from do
--   let pcfg : Path.Config := { outRoot := "", packages := {} }
--   let s ← IO.FS.readFile "/home/mario/Documents/lean/lean/library/test.ast.json"
--   -- let s ← IO.FS.readFile "/home/mario/Documents/lean/mathport/PreData/lean3/init/meta/case_tag.ast.json"
--   -- let s ← IO.FS.readFile "/home/mario/Documents/lean/mathport/PreData/mathlib3/ring_theory/nullstellensatz.ast.json"
--   let json ← Json.parse s
--   let raw@⟨ast, file, level, expr⟩ ← fromJson? json (α := Parse.RawAST3)
--   let ⟨prel, imp, commands, inot, icmd⟩ ← raw.toAST3
--   let level := Parse.buildLevels level
--   let expr := Parse.buildExprs level expr
--   let commands := ast[ast[file].get!.children'[2]].get!.children'
--   let cmdCtx := { fileName := "<input>", fileMap := dummyFileMap }
--   let env ← getEnv
--   let mut opts : Options := {}
--   opts := opts.setBool `trace.PrettyPrinter.parenthesize true
--   -- opts := opts.setBool `trace.PrettyPrinter.format true
--   let s := Elab.Command.mkState (← getEnv) {} opts
--   let mut i := 0
--   for c in commands[i:] do
--     println! "cmd[{i}]"; i := i + 1
--     -- println! (repr (← Parse.getNode c |>.run ast expr)).group ++ "\n"
--     -- println! (repr (← Parse.getCommand c |>.run ast expr).kind).group ++ "\n"
--     let res ← Parse.getCommand c |>.run ast expr
--     Elab.Command.CommandElabM.toIO (ctx := cmdCtx) (s := s) do
--       let ⟨fmt, _⟩ ← Mathport.AST3toData4 ⟨none, #[], #[res], inot, icmd⟩ pcfg
--       println! "{fmt}"
--       printTraces

-- #eval show CoreM Unit from do
--   let ⟨ast⟩ ← parseAST3 "/home/mario/Documents/lean/lean/library/init/logic.ast.json"
--   let ⟨stx, _⟩ ← match AST3toData4 ⟨ast[290:292].toArray⟩ with
--   | Except.ok e => e
--   | Except.error e => throwError "{e}"
--   -- let stx := stx[1][0]
--   println! "{stx[1]}\n\n"
--   let stx ← parenthesize Parser.Module.module.parenthesizer stx
--   println! "{stx}\n\n"
--   let fmt ← format Parser.Module.module.formatter stx
--   println! "{fmt}"
