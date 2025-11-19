#! /usr/bin/env -S uv run
# /// script
# requires-python = ">=3.13"
# dependencies = [
#   "docutils~=0.21.2",
#   "mdformat~=0.7.22",
# ]
# ///

import os
import re
import sys

import docutils.frontend
import docutils.nodes as nodes
import docutils.parsers.rst
import docutils.utils
import mdformat


class Visitor(nodes.NodeVisitor):
	def __init__(self, show_text=False, *args, **kwargs):
		super().__init__(*args, **kwargs)
		self.show_text = show_text
		self.depth = 0

	def unknown_visit(self, node: nodes.Node):
		if isinstance(node, nodes.Element):
			print(f'{self.depth * "  "}@{node.tagname}')
		else:
			assert isinstance(node, nodes.Text)
			if self.show_text:
				print(f'{self.depth * "  "}Text({repr(f"{node.astext()[:20]}...")})')
		self.depth += 1

	def unknown_departure(self, node: nodes.Node):
		self.depth -= 1


class Translator(nodes.NodeVisitor):
	def __init__(self, *args, **kwargs):
		super().__init__(*args, **kwargs)
		self.output = ''
		self.list_depth = 0

	def visit_Text(self, node: nodes.Text):
		self.output += node.astext()

	def depart_Text(self, node: nodes.Text):
		pass

	def visit_literal(self, node: nodes.literal):
		self.output += '`'

	def depart_literal(self, node: nodes.literal):
		self.output += '`'

	def visit_paragraph(self, node: nodes.paragraph):
		# multiple <paragraph>s in a <definition>
		if self.list_depth and node is not node.parent.children[0]:
			self.output = f'{self.output.rstrip()}\n{self.list_depth * "  "}'

	def depart_paragraph(self, node: nodes.paragraph):
		self.output += '\n\n'

	def visit_reference(self, node: nodes.reference):
		self.output += '<' if node.has_key('refuri') else '['

	def depart_reference(self, node: nodes.reference):
		self.output += (
			'>'
			if node.has_key('refuri')
			else f'](https://mpv.io/manual/stable/#{"-".join(node["refname"].split())})'
		)

	def visit_literal_block(self, node: nodes.literal_block):
		self.output += f'```{"" if "\n" in node.astext() else "text"}\n'

	def depart_literal_block(self, node: nodes.literal_block):
		self.output += '\n```\n\n'

	def visit_emphasis(self, node: nodes.emphasis):
		self.output += '*'

	def depart_emphasis(self, node: nodes.emphasis):
		self.output += '*'

	def visit_block_quote(self, node: nodes.block_quote):
		pass

	def depart_block_quote(self, node: nodes.block_quote):
		pass

	def visit_definition_list(self, node: nodes.definition_list):
		self.list_depth += 1

	def depart_definition_list(self, node: nodes.definition_list):
		self.list_depth -= 1
		self.output += '\n'  # see depart_definition

	def visit_definition_list_item(self, node: nodes.definition_list_item):
		pass

	def depart_definition_list_item(self, node: nodes.definition_list_item):
		pass

	def visit_term(self, node: nodes.term):
		self.output += f'{(self.list_depth - 1) * "  "}- '

	def depart_term(self, node: nodes.term):
		self.output += ': '

	def visit_definition(self, node: nodes.definition):
		pass

	def depart_definition(self, node: nodes.definition):
		self.output = f'{self.output.rstrip()}\n'

	def visit_bullet_list(self, node: nodes.bullet_list):
		self.list_depth += 1

	def depart_bullet_list(self, node: nodes.bullet_list):
		self.list_depth -= 1
		self.output += '\n'  # see depart_list_item

	def visit_list_item(self, node: nodes.list_item):
		self.output += f'{(self.list_depth - 1) * "  "}- '

	def depart_list_item(self, node: nodes.list_item):
		self.output = f'{self.output.rstrip()}\n'

	def visit_admonition(self, node: nodes.admonition):
		pass

	def depart_admonition(self, node: nodes.admonition):
		pass

	def visit_title(self, node: nodes.title):
		pass

	def depart_title(self, node: nodes.title):
		self.output += ': '  # special case


if len(sys.argv) != 3:
	print('usage: gen.py ./lua.rst ./outdir')
	sys.exit(0)
_, rst, outdir = sys.argv

with open(rst) as file:
	text = file.read()
parser = docutils.parsers.rst.Parser()
settings = docutils.frontend.get_default_settings(docutils.parsers.rst.Parser())
document = docutils.utils.new_document('lua.rst', settings=settings)
parser.parse(text, document)
# document.walkabout(Visitor(show_text=True, document=document))

modules: dict[str, dict[str, str]] = {}
for definition_list in document.findall(
	lambda n: isinstance(n, nodes.definition_list) and isinstance(n.parent, nodes.section)
):
	for item in definition_list.children:
		assert isinstance(item, nodes.definition_list_item)
		term, definition = item.children
		assert isinstance(term, nodes.term)
		assert isinstance(definition, nodes.definition)

		translator = Translator(document)
		for child in definition.children:
			child.walkabout(translator)
		comment = mdformat.text(translator.output, options={'wrap': 80})

		for literal in term.findall(lambda n: isinstance(n, nodes.literal)):
			fn = literal.astext().replace('[', '').replace(']', '')
			fn = re.sub(r'\|\w+', '', fn)
			fn = re.sub(r'\s*,\s*', ', ', fn)
			module = 'mp'
			if not fn.startswith('mp.'):
				comps = fn.split('.', 1)
				if len(comps) > 1:
					module = comps[0]
			modules.setdefault(module, {})[fn] = comment

os.makedirs(outdir, exist_ok=True)
for module, functions in modules.items():
	with open(os.path.join(outdir, f'{module}.lua'), 'w') as file:
		file.write('--- generated from https://github.com/mpv-player/mpv/blob/master/DOCS/man/lua.rst\n')
		file.write(
			'--- @meta mp\n\nmp = {}\nmp.msg = require "mp.msg"\n\n'
			if module == 'mp'
			else f'--- @meta mp.{module}\n\nlocal {module} = {{}}\n\n'
		)
		for fn, comment in functions.items():
			for line in comment.splitlines():
				file.write(f'--- {line}\n' if line else '---\n')
			file.write(f'function {fn} end\n\n')
		file.write(f'return {module}\n')
