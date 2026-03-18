import gleam/dict
import gleam/string_tree
import gleeunit/should
import handles/ctx
import handles/internal/engine
import handles/internal/parser
import handles/internal/tokenizer

// Reproduction for GitHub issue #8:
// `:${{{ var }}_SUFFIX:=...}` style shell parameter expansion.
// https://github.com/Olian04/gleam_handles/issues/8

const input_template_env_file = ": ${{{ pkg_name }}_env_file:=\"{{ conf_dir }}/{{ pkg_name }}.env\"}"

const input_template_conf_dir = ": ${{{ conf_dir_var }}_CONF_DIR:=\"${confdir}\"}"

// Intended output (as per the issue author's goal): triple braces are used to
// splice template values into a *shell variable name* inside `${...}`.
const input_context = ctx.Dict(
  [
    ctx.Prop("pkg_name", ctx.Str("pkg")),
    ctx.Prop("conf_dir", ctx.Str("/etc")),
    ctx.Prop("conf_dir_var", ctx.Str("pkg")),
  ],
)

const expected_output_env_file = ": ${pkg_env_file:=\"/etc/pkg.env\"}"

const expected_output_conf_dir = ": ${pkg_CONF_DIR:=\"${confdir}\"}"

pub fn engine_env_file_test() {
  tokenizer.run(input_template_env_file)
  |> should.be_ok
  |> parser.run
  |> should.be_ok
  |> engine.run(input_context, dict.new())
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal(expected_output_env_file)
}

pub fn engine_conf_dir_test() {
  tokenizer.run(input_template_conf_dir)
  |> should.be_ok
  |> parser.run
  |> should.be_ok
  |> engine.run(input_context, dict.new())
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal(expected_output_conf_dir)
}
