import tempfile
import unittest
from pathlib import Path

from scripts.update_image import update_image


class UpdateImageTests(unittest.TestCase):
    def test_updates_image_and_preserves_resources(self):
        source = Path("k8s/kustomization.yaml").read_text(encoding="utf-8")
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "kustomization.yaml"
            target.write_text(source, encoding="utf-8")
            update_image(target, "example/test", "a" * 40)
            result = target.read_text(encoding="utf-8")
        self.assertIn("newName: example/test", result)
        self.assertIn('newTag: "' + "a" * 40 + '"', result)
        self.assertEqual(source.split("images:")[0], result.split("images:")[0])

    def test_refuses_invalid_tag_without_modifying_file(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "kustomization.yaml"
            target.write_text("original", encoding="utf-8")
            with self.assertRaises(ValueError):
                update_image(target, "example/test", "latest")
            self.assertEqual(target.read_text(encoding="utf-8"), "original")
