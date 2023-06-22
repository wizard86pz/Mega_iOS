@testable import MEGA
import MEGADataMock
import MEGADomain
import XCTest

final class NodeValidationRepositoryTests: XCTestCase {

    func test_isNode_desdendantOf_ancestor() async {
        let grandParentNode = MockNode(handle: 1)
        let parentNode = MockNode(handle: 2, parentHandle: 1)
        let childNode = MockNode(handle: 3, parentHandle: 2)
        
        let sdk = MockSdk(nodes: [grandParentNode, parentNode, childNode])
        let repo = NodeValidationRepository(sdk: sdk)
        
        let isChildDescendantOfGrandParent = await repo.isNode(childNode.toNodeEntity(), descendantOf: grandParentNode.toNodeEntity())
        XCTAssertTrue(isChildDescendantOfGrandParent)
        
        let isChildDescendantOfParent = await repo.isNode(childNode.toNodeEntity(), descendantOf: parentNode.toNodeEntity())
        XCTAssertTrue(isChildDescendantOfParent)
        
        let isParentDescendantOfChild = await repo.isNode(parentNode.toNodeEntity(), descendantOf: childNode.toNodeEntity())
        XCTAssertFalse(isParentDescendantOfChild)
        
        let isGrandParentDescendantOfParent = await repo.isNode(grandParentNode.toNodeEntity(), descendantOf: parentNode.toNodeEntity())
        XCTAssertFalse(isGrandParentDescendantOfParent)
        
        let isGrandParentDescendantOfChild = await repo.isNode(grandParentNode.toNodeEntity(), descendantOf: childNode.toNodeEntity())
        XCTAssertFalse(isGrandParentDescendantOfChild)
    }
}
