"""
Custom ranger commands.
"""

import os
from ranger.api.commands import Command


class trash(Command):
    """:trash

    Moves the selection to the system trash using rifle's 'trash' label.

    Fixes a bug in ranger 1.9.4 where the built-in trash command passes
    relative-path strings to execute_file(), which expects FileObjects with
    a .path attribute — causing an AttributeError crash.
    """

    allow_abbrev = False
    escape_macros_for_shell = True

    def execute(self):
        from functools import partial

        def is_directory_with_files(path):
            return (
                os.path.isdir(path)
                and not os.path.islink(path)
                and len(os.listdir(path)) > 0
            )

        cwd = self.fm.thisdir
        tfile = self.fm.thisfile
        if not cwd or not tfile:
            self.fm.notify("Error: no file selected for trash!", bad=True)
            return

        # Keep FileObjects so execute_file() can call f.path on them.
        files = self.fm.thistab.get_selection()
        many_files = cwd.marked_items or is_directory_with_files(tfile.path)

        confirm = self.fm.settings.confirm_on_delete
        if confirm != 'never' and (confirm != 'multiple' or many_files):
            display_names = [f.relative_path for f in files]
            self.fm.ui.console.ask(
                "Confirm trash: %s (y/N)" % ', '.join(display_names),
                partial(self._question_callback, files),
                ('n', 'N', 'y', 'Y'),
            )
        else:
            self.fm.execute_file(files, label='trash')

    def tab(self, tabnum):
        return self._tab_directory_content()

    def _question_callback(self, files, answer):
        if answer in ('y', 'Y'):
            self.fm.execute_file(files, label='trash')
