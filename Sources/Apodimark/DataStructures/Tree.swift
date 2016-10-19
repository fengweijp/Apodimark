
// An append-depth-first-only tree

struct DepthLevel {
    fileprivate var _level: Int
    
    init(_ level: Int) {
        self._level = level
    }
    
    func incremented() -> DepthLevel {
        return .init(_level+1)
    }
    
    func decremented() -> DepthLevel {
        return .init(_level-1)
    }
    
    static func == (lhs: DepthLevel, rhs: DepthLevel) -> Bool {
        return lhs._level == rhs._level
    }
}

struct TreeNode <T> {
    let data: T
    var end: Int
    
    init(data: T, end: Array<T>.Index) {
        (self.data, self.end) = (data, end)
    }
}

final class Tree <T> {
    
    var buffer: Array<TreeNode<T>>
    var lastStrand: [Array<T>.Index]
    
    init() {
        (self.buffer, self.lastStrand) = ([], [])
    }
    
    func last(depthLevel: DepthLevel) -> T? {
        guard depthLevel._level >= 0 && depthLevel._level < lastStrand.count else { return nil }
        return buffer[lastStrand[depthLevel._level]].data
    }
    
    func append(_ data: T, depthLevel level: DepthLevel = .init(0)) {
        // if level is 0, then lastStrand is empty
        guard level._level <= lastStrand.count else {
            fatalError()
        }
        
        // update lastStrand
        lastStrand.removeSubrange(level._level ..< lastStrand.endIndex)
        lastStrand.append(buffer.endIndex)
        
        // update range of parents
        for parentIndex in lastStrand.prefix(upTo: level._level) {
            buffer[parentIndex].end += 1
        }
        
        // append node
        buffer.append(TreeNode(data: data, end: buffer.endIndex))
    }

    func append <C: Collection> (strand: C, depthLevel level: DepthLevel = .init(0)) where
        C.Iterator.Element == T
    {
        guard level._level <= lastStrand.count else {
            fatalError()
        }
        
        let strandLength: Int = numericCast(strand.count)
        
        // update lastStrand
        lastStrand.removeSubrange(level._level ..< lastStrand.endIndex)
        lastStrand.append(contentsOf: buffer.endIndex ..< buffer.endIndex + strandLength)
        
        // update range of parents
        for parentIndex in lastStrand.prefix(upTo: level._level) {
            buffer[parentIndex].end += strandLength
        }
        
        // append nodes
        buffer.append(contentsOf: strand.map { TreeNode(data: $0, end: buffer.endIndex + strandLength-1) })
    }

    func makeIterator() -> TreeIterator<T> {
        return TreeIterator(self)
    }
}

enum Result {
    case success
    case failure
}

struct TreeIterator <T>: IteratorProtocol, Sequence {
    
    let tree: Tree<T>
    let endIndex: Array<T>.Index
    var index: Array<T>.Index
    
    fileprivate init(_ tree: Tree<T>) {
        (self.tree, self.endIndex) = (tree, tree.buffer.endIndex)
        self.index = 0
    }
    
    fileprivate init(_ tree: Tree<T>, startIndex: Array<T>.Index, endIndex: Array<T>.Index) {
        (self.tree, self.endIndex) = (tree, endIndex)
        self.index = startIndex
    }
    
    mutating func next() -> (T, TreeIterator?)? {
        
        guard index < endIndex else {
            return nil
        }
        
        let end = tree.buffer[index].end
        
        defer {
            index = end+1
        }
        
        return (tree.buffer[index].data, diving())
    }
    
    private func diving() -> TreeIterator<T>? {
        
        guard index < tree.buffer.endIndex else {
            return nil
        }
        
        let end = tree.buffer[index].end
        
        guard index.distance(to: end) > 0 else {
            return nil
        }
        
        return TreeIterator(tree, startIndex: index+1, endIndex: end+1)
    }
    
    func makeIterator() -> TreeIterator<T> {
        return self
    }
}

