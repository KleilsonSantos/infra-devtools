"""
Conversor de relatórios JUnit XML para o formato compatível com o SonarQube.

Este módulo realiza parsing seguro de arquivos XML contendo resultados de testes
e os transforma no formato `testExecutions` usado para análise de cobertura.
"""

import os
import sys
from typing import Optional

import defusedxml.ElementTree as ET  # type: ignore[import-untyped]


def convert_junit_to_sonar(junit_xml_path: str, sonar_xml_path: str) -> None:
    """Convert a JUnit XML report to the format expected by SonarQube."""
    if not os.path.exists(junit_xml_path):
        print(f"❌ Arquivo '{junit_xml_path}' não encontrado.")
        sys.exit(1)

    try:
        tree = ET.parse(junit_xml_path)  # type: ignore[attr-defined]
        root = tree.getroot()
        assert root is not None
    except ET.ParseError as e:  # type: ignore[attr-defined]
        print(f"❌ Erro ao parsear XML: {e}")
        sys.exit(1)

    if root.tag != "testsuites":
        print(
            f"❌ Formato inesperado: esperado 'testsuites', mas encontrado '{root.tag}'"
        )
        sys.exit(1)

    sonar_root = ET.Element("testExecutions", version="1")  # type: ignore[attr-defined]

    for testsuite in root.findall("testsuite"):
        for testcase in testsuite.findall("testcase"):
            classname: Optional[str] = testcase.get("classname")
            testname: Optional[str] = testcase.get("name")
            duration: Optional[str] = testcase.get("time")

            if not classname or not testname or not duration:
                print(f"⚠️ Ignorando teste com dados incompletos: {testcase.attrib}")
                continue

            file_element = ET.SubElement(sonar_root, "file", path=classname)  # type: ignore[attr-defined]
            ET.SubElement(file_element, "testCase", name=testname, duration=duration)  # type: ignore[attr-defined]

    if not list(sonar_root):
        print("⚠️ Nenhum teste encontrado no XML original.")
        sys.exit(1)

    tree_sonar = ET.ElementTree(sonar_root)  # type: ignore[attr-defined]
    tree_sonar.write(sonar_xml_path, encoding="utf-8", xml_declaration=True)

    print(f"✅ Conversão concluída! Arquivo salvo em '{sonar_xml_path}'.")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(
            "❌ Uso incorreto! Esperado: python convert_junit_to_sonar.py <junit_xml_path> <sonar_xml_path>"
        )
        sys.exit(1)

    convert_junit_to_sonar(sys.argv[1], sys.argv[2])
