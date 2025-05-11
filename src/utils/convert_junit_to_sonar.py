import xml.etree.ElementTree as ET
import sys
import os

def convert_junit_to_sonar(junit_xml_path, sonar_xml_path):
    """Converte um relatório JUnit XML para o formato esperado pelo SonarQube"""
    
    if not os.path.exists(junit_xml_path):
        print(f"❌ Arquivo '{junit_xml_path}' não encontrado.")
        sys.exit(1)

    try:
        tree = ET.parse(junit_xml_path)
        root = tree.getroot()
    except ET.ParseError as e:
        print(f"❌ Erro ao parsear XML: {e}")
        sys.exit(1)

    if root.tag != "testsuites":
        print(f"❌ Formato inesperado: esperado 'testsuites', mas encontrado '{root.tag}'")
        sys.exit(1)

    sonar_root = ET.Element("testExecutions", version="1")

    for testsuite in root.findall("testsuite"):
        for testcase in testsuite.findall("testcase"):
            classname = testcase.get("classname")
            testname = testcase.get("name")
            duration = testcase.get("time")

            if not classname or not testname or not duration:
                print(f"⚠️ Ignorando teste com dados incompletos: {testcase.attrib}")
                continue

            file_element = ET.SubElement(sonar_root, "file", path=classname)
            ET.SubElement(file_element, "testCase", name=testname, duration=duration)

    if not list(sonar_root):
        print("⚠️ Nenhum teste encontrado no XML original.")
        sys.exit(1)

    tree_sonar = ET.ElementTree(sonar_root)
    tree_sonar.write(sonar_xml_path, encoding="utf-8", xml_declaration=True)
    print(f"✅ Conversão concluída! Arquivo salvo em '{sonar_xml_path}'.")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("❌ Uso incorreto! Esperado: python convert_junit_to_sonar.py <junit_xml_path> <sonar_xml_path>")
        sys.exit(1)

    convert_junit_to_sonar(sys.argv[1], sys.argv[2])
