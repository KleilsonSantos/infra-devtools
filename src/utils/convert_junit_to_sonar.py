"""
JUnit XML report converter to SonarQube-compatible format.

This module performs secure parsing of XML files containing test results
and transforms them into the `testExecutions` format used by SonarQube
for coverage and test execution analysis.
"""

import os
import sys
import xml.etree.ElementTree as ET
from typing import Optional

from defusedxml.ElementTree import parse  # ✅ Usamos só o parse seguro


def convert_junit_to_sonar(junit_xml_path: str, sonar_xml_path: str) -> None:
    """Convert a JUnit XML report to the format expected by SonarQube."""
    if not os.path.exists(junit_xml_path):
        print(f"❌ File '{junit_xml_path}' not found.")
        sys.exit(1)

    try:
        tree = parse(junit_xml_path)  # ✅ seguro contra XML malicioso
        root = tree.getroot()
        assert root is not None
    except ET.ParseError as e:
        print(f"❌ Error parsing XML: {e}")
        sys.exit(1)

    if root.tag != "testsuites":
        print(f"❌ Unexpected format: expected 'testsuites', but found '{root.tag}'")
        sys.exit(1)

    sonar_root = ET.Element("testExecutions", version="1")

    for testsuite in root.findall("testsuite"):
        for testcase in testsuite.findall("testcase"):
            classname: Optional[str] = testcase.get("classname")
            testname: Optional[str] = testcase.get("name")
            duration: Optional[str] = testcase.get("time")

            if not classname or not testname or not duration:
                print(f"⚠️ Ignoring test with incomplete data: {testcase.attrib}")
                continue

            file_element = ET.Element("file", path=classname)
            ET.SubElement(file_element, "testCase", name=testname, duration=duration)
            sonar_root.append(file_element)

    if not list(sonar_root):
        print("⚠️ No tests found in the original XML.")
        sys.exit(1)

    tree_sonar = ET.ElementTree(sonar_root)
    tree_sonar.write(sonar_xml_path, encoding="utf-8", xml_declaration=True)

    print(f"✅ Conversion completed! File saved at '{sonar_xml_path}'.")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(
            "❌ Incorrect usage! Expected: python convert_junit_to_sonar.py "
            "<junit_xml_path> <sonar_xml_path>"
        )
        sys.exit(1)

    convert_junit_to_sonar(sys.argv[1], sys.argv[2])
