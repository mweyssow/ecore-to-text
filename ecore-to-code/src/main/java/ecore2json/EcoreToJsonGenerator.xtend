package ecore2json

import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.emf.ecore.xmi.impl.EcoreResourceFactoryImpl;
import org.eclipse.emf.ecore.EPackage;
import org.eclipse.emf.ecore.impl.EClassImpl;
import org.eclipse.emf.ecore.InternalEObject
import java.util.stream.Collectors

class EcoreToJsonGenerator {
	/**
	 * Generate a tree representation of an Ecore model.
	 * The tree is generated by considering: 
	 * 		- Classifiers (EClass)
	 * 		- Attributes (EAttribute)
	 * 		- Associations/Containments (EReference)
	 * Outputs the tree in a .json file.
	 * 
	 * @param  filePath 	an absolute path giving the base location of the Ecore model
	 * @return String		the json representation of the Ecore model
	 * 
	 */
	def String generate(String filePath) {
		val resourceSet = new ResourceSetImpl;
		resourceSet.getResourceFactoryRegistry().getExtensionToFactoryMap().put(
			"ecore", new EcoreResourceFactoryImpl
		);
		val resource = resourceSet.getResource(
			URI.createFileURI(filePath), true
		);
		
		val model = resource.getContents().get(0) as EPackage;
		return generateCode(model);
	}
	
	def String generateCode(EPackage model) {
		var classifiers = model.getEClassifiers();
		// filter enumerations -> keep only classes
		var cls = classifiers.stream
			.collect(Collectors.toList)
			.filter(e | e instanceof EClassImpl)
			.map(e | e as EClassImpl);

		'''
		{
			"root": "<MODEL>",
			"children": [
				�FOR classifier : cls SEPARATOR ','�
					{
						"root": "<CLS>",
						"name": "�classifier.name�",
						"attrs": [
							�FOR member : classifier.getEAttributes() SEPARATOR ','�
								{
									�var eAttr = member.EType�
									�var eAttrData = eAttr as InternalEObject�
									�var eAttrDataProxy = eAttrData.eProxyURI as URI�
									�IF eAttrDataProxy !== null && eAttr.name === null�
										"�eAttrDataProxy.fragment.replace('/', '')�": "�member.name�"
									�ELSE�
										"�eAttr.name�": "�member.name�"
									�ENDIF�
								}
							�ENDFOR�
						],
						"assocs": [
							�FOR member : classifier.getEAllReferences() SEPARATOR ','�
								{
									�var eRefName = member.getEReferenceType().name�
									�IF eRefName !== null�
										"�eRefName�": "�member.name�"
									�ENDIF�
								}
							�ENDFOR�
						]
					}
				�ENDFOR�			
			]
		}
  		'''
	}
}