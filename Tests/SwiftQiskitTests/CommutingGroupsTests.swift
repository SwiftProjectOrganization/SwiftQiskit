import Foundation
import Testing
@testable import SwiftQiskit

struct CommutingGroupsTests {

    // MARK: - PauliString.isQubitWiseCommuting(with:)

    @Test func `identical labels are qubit-wise commuting`() {
        #expect(PauliString("ZZ").isQubitWiseCommuting(with: PauliString("ZZ")))
    }

    @Test func `an all-identity string is qubit-wise commuting with anything`() {
        #expect(PauliString("II").isQubitWiseCommuting(with: PauliString("XY")))
        #expect(PauliString("XY").isQubitWiseCommuting(with: PauliString("II")))
    }

    @Test func `non-overlapping active qubits are qubit-wise commuting`() {
        // ZI and IZ never both specify a label on the same qubit.
        #expect(PauliString("ZI").isQubitWiseCommuting(with: PauliString("IZ")))
    }

    @Test func `a shared qubit with different non-identity labels is not qubit-wise commuting`() {
        #expect(!PauliString("ZZ").isQubitWiseCommuting(with: PauliString("YY")))
        #expect(!PauliString("XI").isQubitWiseCommuting(with: PauliString("YI")))
    }

    @Test func `partial overlap is fine as long as the shared qubit agrees`() {
        // ZI and ZZ agree on qubit 0 (both Z); qubit 1 is I on the left, Z on the right.
        #expect(PauliString("ZI").isQubitWiseCommuting(with: PauliString("ZZ")))
    }

    // MARK: - Hamiltonian.commutingGroups() — hand-traced cases

    /// Page `18VQE`'s six-term H₂ Hamiltonian, reused from `PauliStringTests.swift`.
    private static let h2Coefficients: [Double] = [-0.4804, 0.3435, -0.4347, 0.5716, 0.0910, 0.0910]
    private static var h2Hamiltonian: Hamiltonian {
        Hamiltonian([
            PauliString("II", coefficient: h2Coefficients[0]),
            PauliString("ZI", coefficient: h2Coefficients[1]),
            PauliString("IZ", coefficient: h2Coefficients[2]),
            PauliString("ZZ", coefficient: h2Coefficients[3]),
            PauliString("YY", coefficient: h2Coefficients[4]),
            PauliString("XX", coefficient: h2Coefficients[5]),
        ])
    }

    /// `II, ZI, IZ, ZZ` are pairwise QWC (any two agree everywhere they both specify a
    /// label), so the greedy algorithm collects them into one group; `YY` conflicts with
    /// `ZI`/`ZZ` on qubit 0 and `XX` conflicts with both `ZZ` and `YY` — three groups total.
    @Test func `H2 Hamiltonian groups into three qubit-wise-commuting sets`() {
        let groups = Self.h2Hamiltonian.commutingGroups()
        #expect(groups.count == 3)

        let labelSets = groups.map { Set($0.map(\.label)) }
        #expect(labelSets.contains(["II", "ZI", "IZ", "ZZ"]))
        #expect(labelSets.contains(["YY"]))
        #expect(labelSets.contains(["XX"]))
    }

    @Test func `a fully mutually-commuting Hamiltonian collapses to one group`() {
        let hamiltonian = Hamiltonian([
            PauliString("ZII"), PauliString("IZI"), PauliString("IIZ"), PauliString("ZZZ"),
        ])
        #expect(hamiltonian.commutingGroups().count == 1)
    }

    @Test func `pairwise-conflicting terms each get their own group`() {
        // X, Y, Z on a single qubit conflict pairwise, so no two can ever share a group.
        let hamiltonian = Hamiltonian([PauliString("X"), PauliString("Y"), PauliString("Z")])
        let groups = hamiltonian.commutingGroups()
        #expect(groups.count == 3)
        #expect(groups.allSatisfy { $0.count == 1 })
    }

    // MARK: - General invariants

    /// Every returned group is genuinely pairwise qubit-wise commuting, and the groups
    /// together contain exactly the original terms — no term dropped, duplicated, or
    /// invented — checked for the H₂ case and a larger synthetic Hamiltonian covering
    /// every non-trivial single-Pauli-per-qubit 2-qubit string.
    private func assertValidPartition(_ hamiltonian: Hamiltonian) {
        let groups = hamiltonian.commutingGroups()

        for group in groups {
            for i in group.indices {
                for j in group.indices where j != i {
                    #expect(group[i].isQubitWiseCommuting(with: group[j]))
                }
            }
        }

        let flattened = groups.flatMap { $0 }
        #expect(flattened.count == hamiltonian.terms.count)
        // Every original term appears exactly once across the groups (PauliString is
        // Hashable, so a multiset comparison via sorted labels is enough here since this
        // Hamiltonian's terms all have distinct labels).
        #expect(Set(flattened.map(\.label)) == Set(hamiltonian.terms.map(\.label)))
    }

    @Test func `H2 grouping is a valid partition of its terms`() {
        assertValidPartition(Self.h2Hamiltonian)
    }

    @Test func `grouping every non-trivial single-Pauli-per-qubit 2-qubit string is a valid partition`() {
        let bases: [PauliBasis?] = [nil, .x, .y, .z]
        var terms: [PauliString] = []
        for first in bases {
            for second in bases where !(first == nil && second == nil) {
                terms.append(PauliString(labels: [first, second]))
            }
        }
        assertValidPartition(Hamiltonian(terms))
    }

    @Test func `grouping is deterministic for a fixed term order`() {
        let hamiltonian = Self.h2Hamiltonian
        let first = hamiltonian.commutingGroups().map { $0.map(\.label) }
        let second = hamiltonian.commutingGroups().map { $0.map(\.label) }
        #expect(first == second)
    }
}
