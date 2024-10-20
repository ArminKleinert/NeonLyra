package alp3.task21;

import java.math.BigInteger;
import java.util.*;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Predicate;
import java.util.stream.Collectors;

public class SAT {
    private final AtomicLong stepsSimplifying;
    private final AtomicLong stepsResolving;
    private final HashMap<String, Integer> variables;
    private Set<Set<Integer>> clauses;

    public SAT(Iterable<String> strClauses) {
        stepsSimplifying = new AtomicLong(0);
        stepsResolving = new AtomicLong(0);
        variables = new HashMap<>();
        variables.put("0", 0); // Literal constant 0
        variables.put("1", 1); // Literal constant 1
        clauses = new TreeSet<>(this::clauseCompare);
        for (String clause : strClauses) {
            Set<Integer> clause1 = parseStringClause(clause, variables);
            Set<Integer> clauseL = new HashSet<>(clause1);
            clauses.add(clauseL);
        }
    }

    /* Simplifier */

    /*
    Das Vereinfachen der einzelnen Klauseln funktioniert wie folgt:
    - Entferne 0-en
    - Wenn eine 1 vorhanden ist, leere die Klausel und füge eine 1 ein. (Ausdruck immer wahr)
    - Wenn das negative Äquivalent einer Variable vorhanden ist, leere die Klausel und füge eine 1 ein. (Ausdruck immer wahr)
     */

    /**
     * Same as simplifyClause(clause, -1)
     *
     * @param clause
     * @return
     */
    private Set<Integer> simplifyClause(Set<Integer> clause) {
        return simplifyClause(clause, -1); // No limit
    }

    /**
     * Simplify a clause. Stop after spcified number of steps unless the clause was simplified already.
     *
     * @param clause
     * @param recursionLimit If this number reaches 0, stop simplifying. If it is negative, run until no more simplifying can be done.
     * @return The simplified clause
     */
    private Set<Integer> simplifyClause(Set<Integer> clause, int recursionLimit) {
        // Convert all -1s to 0s (n steps)
        clause = clause.stream().map(i -> (i == -1) ? 0 : i).collect(Collectors.toSet());
        stepsSimplifying.addAndGet(clause.size());
        if (recursionLimit == 0) {
            return clause;
        } else if (clause.contains(0)) {
            clause.remove(0);
            stepsSimplifying.addAndGet(clause.size());
            return simplifyClause(clause, recursionLimit - 1);
        } else if (clause.contains(1)) {
            return clauseAlwaysTrue(clause);
        } else if (clause.size() < 2) {
            return clause;
        } else {
            for (Integer i : clause) {
                stepsSimplifying.addAndGet(1);
                if (clause.contains(-i)) {
                    // Clause contains a variable and its negation.
                    // E.g. x1 or -x1
                    // This always simplifies to 0
                    return clauseAlwaysTrue(clause);
                }
            }
            return clause;
        }
    }

    /*
    Wenn eine Klausel immer Wahr ist, leere sie und füge eine 1 hinzu.
     */
    private Set<Integer> clauseAlwaysTrue(Set<Integer> clause) {
        stepsSimplifying.addAndGet(1);
        clause.clear();
        clause.add(1);
        return clause;
    }

    /*
    Das Vereinfachen aller Klauseln funktioniert wie folgt:
    - Vereinfache jede Klausel
    - Ist eine 0-Klausel vorhanden -> Entferne alle Klauseln
    - Entferne alle 1-en
    */
    private SAT simplifyClauses() {
        clauses = simplifyClauses(clauses);
        return this;
    }

    private boolean removeFromClause(Set<Integer> clause, int var) {
        stepsSimplifying.addAndGet(1);
        return clause.remove(var);
    }

    private boolean simplifyBoth(Set<Integer> clause, Set<Integer> clause1) {
        stepsSimplifying.addAndGet(((long) clause.size()) + clause1.size());
        return clause.retainAll(clause1) && clause1.retainAll(clause);
    }

    /*
    Das Vereinfachen aller Klauseln funktioniert wie folgt:
    - Vereinfache jede Klausel
    - Ist eine 0-Klausel vorhanden -> Entferne alle Klauseln
    - Entferne alle 1-en
    */
    private Set<Set<Integer>> simplifyClauses(Set<Set<Integer>> clauses) {
        stepsSimplifying.addAndGet(clauses.size() * 2L);
        clauses = clauses.stream()
                .map(this::simplifyClause)
                .distinct()
                .filter(Predicate.not(this::isTrueClause))
                .collect(Collectors.toSet());

        stepsSimplifying.addAndGet(clauses.size());
        if (clauses.stream().anyMatch(this::isFalseClause)) {
            clauses.clear();
        } else {
            boolean anyChange = false;
            for (var clause : clauses) {
                if (isSingleVariable(clause)) {
                    int first = clause.stream().findFirst().get();
                    for (var clause1 : clauses) {
                        if (!isSingleVariable(clause1)) {
                            anyChange = anyChange || removeFromClause(clause1, -first);
                        }
                    }
                } else {
                    for (var clause1 : clauses) {
                        if (clausesEquiv(clause, clause1) && !isSingleVariable(clause1)) {
                            anyChange = anyChange || simplifyBoth(clause, clause1);
                        }
                    }
                }
            }
            if (anyChange) clauses = simplifyClauses(clauses);
        }

        return clauses;
    }

    /* Validator */

    private int clauseCompare(Set<Integer> clause0, Set<Integer> clause1) {
        return clause0.toString().compareTo(clause1.toString());
    }

    /*
    Check whether 2 clauses have the same result.
    E.g. (a v -b) and (a v b)
     */
    private boolean clausesEquiv(Set<Integer> clause0, Set<Integer> clause1) {
        stepsSimplifying.addAndGet((long) clause0.size() * clause1.size());
        return clause0.stream().map(Math::abs).filter(clause1::contains).count() == clause0.size() - 1;
    }

    private boolean isSingleVariable(Set<Integer> clause) {
        stepsSimplifying.addAndGet(1);
        return clause.size() == 1 && clause.stream().allMatch(e -> e != 1 && e != 0);
    }

    private boolean isTrueClause(Set<Integer> clause) {
        stepsSimplifying.addAndGet(1);
        return clause.size() == 1 && clause.stream().allMatch(e -> e == 1);
    }

    private boolean isFalseClause(Set<Integer> clause) {
        stepsSimplifying.addAndGet(1);
        return clause.size() == 0 || clause.stream().allMatch(e -> e == 0);
    }

    /* Calculate all combinations of bits */

    public boolean resolveClause(Set<Integer> clause, BigInteger bits) {
        return clause.stream()
                .anyMatch(v -> (v < 0)
                        ? !bits.testBit(-v)
                        : bits.testBit(v));
    }

    // Check whether all clauses are true given the bindings.
    public boolean resolveClauses(Collection<Set<Integer>> clauses, BigInteger bits) {
        return !clauses.isEmpty() && clauses.stream().allMatch(c -> resolveClause(c, bits));
    }

    /*
    Iteriert alle Belegungen der Variablen unter Verwendung eines Bit-Patterns.
     */
    public boolean isResolvable(Set<Set<Integer>> clauses, BigInteger bits, BigInteger allOnes) {
        stepsResolving.addAndGet(1);
        if (resolveClauses(clauses, bits)) {
            // At least 1 resolvable pattern of bits found
            return true;
        } else if (bits.compareTo(allOnes) >= 0) {
            // All tested, none true
            return false;
        } else {
            // Test next pattern
            // To get the next pattern, add 0b10 to the current one. The 2nd bit has to always be 1 and the lowest must be 0
            // Variables: 0,1,a,b
            // Pattern 0110 means that a=1 b=0
            // Pattern 0110 => (1000 | 0010) => 1010
            return isResolvable(clauses, bits.add(BigInteger.TWO).or(BigInteger.TWO), allOnes);
        }
    }

    public boolean isResolvable() {
        var clauses = this.clauses;
        //clauses = simplifyClauses(clauses);
        if (clauses.isEmpty() || clauses.stream().anyMatch(this::isFalseClause))
            return false;
        BigInteger maximum = BigInteger.ZERO.setBit(variables.size()).subtract(BigInteger.TWO);
        return isResolvable(clauses, BigInteger.ZERO, maximum);
    }

    /* Getters and Setters */

    public HashMap<String, Integer> getVariables() {
        return variables;
    }

    public Collection<Set<Integer>> getClauses() {
        return clauses;
    }

    public long getStepsForSimplifying() {
        return stepsSimplifying.longValue();
    }

    public long getStepsForResolving() {
        return stepsResolving.longValue();
    }

    public void resetCounters() {
        stepsSimplifying.set(0);
        stepsResolving.set(0);
    }

    /* Parsers */

    /*
    Das Parsen einer Klausel funktioniert wie folgt:
    - Splitte den String an Leerzeichen
    - Wenn eine Variable gleich -1 ist, ändere sie zu 0
    - Wenn eine Variable gleich -0 ist, ändere sie zu 1
    - Wenn eine Variable (Vorzeichen ignoriert) neu ist, füge sie zu den bekannten Variablen hinzu und weise ihr eine Zahl zu.
    - Füge für die Variable eine Zahl ein. Wenn die Variable negativ ist, negiere die Zahl.
     */

    public static Set<Integer> parseStringClause(String clause, HashMap<String, Integer> variables) {
        String[] vars = clause.split("\\s");
        Set<Integer> output = new HashSet<>();
        for (String v : vars) {
            if (v.isEmpty()) continue;
            if (v.equals("-1")) v = "0";
            if (v.equals("-0")) v = "1";
            boolean negated = v.startsWith("-");
            if (negated) v = v.substring(1);
            var c = v;
            Integer key = variables.get(c);
            if (key == null) {
                key = variables.size();
                variables.put(c, key);
            }
            if (negated) key = -key;
            output.add(key);
        }
        return output;
    }

    public static SAT parse(String s) {
        return new SAT(s.lines().collect(Collectors.toList()));
    }


    /* String conversion */

    private String clauseToString(Set<Integer> clause, Map<Integer, String> inverseVariables) {
        if (clause.isEmpty())
            return "";

        String outStr = clause.stream()
                .map(i -> (i < 0)
                        ? ("-" + inverseVariables.get(-i))
                        : String.valueOf(inverseVariables.get(i)))
                .collect(Collectors.joining(" v "));

        if (clause.size() == 1)
            return outStr;
        else
            return "(" + outStr + ")";
    }

    private List<String> clausesToString(Map<Integer, String> inverseVariables) {
        return clauses.stream().map(c -> clauseToString(c, inverseVariables)).collect(Collectors.toList());
    }

    @Override
    public String toString() {
        Map<Integer, String> inverseVariables = new HashMap<>();
        for (Map.Entry<String, Integer> entry : variables.entrySet()) {
            inverseVariables.put(entry.getValue(), entry.getKey());
        }
        return clausesToString(inverseVariables).stream()
                .filter(Predicate.not(String::isEmpty))
                .collect(Collectors.joining(" ∧ "));
    }

    /*
    Beispiel:
    var s = SAT.parse("0 a\n-a b\n-a b\n-a b\n-a b\na -a c d e");
    // s.variables:    {0=0, 1=1, a=2, b=3, c=4, d=5, e=6}
    // s.clauses:      [[-2, 2, 4, 5, 6], [-2, 3], [0, 2]]
    // s:              (-a v a v c v d v e) ∧ (-a v b) ∧ (0 v a)
    // s.isResolvable: true
    s.simplifyClauses();
    // s.variables:    {0=0, 1=1, a=2, b=3, c=4, d=5, e=6}
    // s.clauses:      [[-2, 3], [2]]
    // s:              (-a v b) ∧ a
    // s.isResolvable: true
     */
    public static void main(String[] args) {
        SAT s;
        s = SAT.parse("a b c\na -b\n-a -b c\n-c\n-c");
        System.out.println("s: " + s);
        System.out.println("Resolvable? " + s.isResolvable() + " Steps simplifying: " + s.getStepsForSimplifying() + " Steps resolving: " + s.getStepsForResolving());
        s.resetCounters();
        s.simplifyClauses();
        System.out.println("Simplified. Steps simplifying: " + s.getStepsForSimplifying());
        s.resetCounters();
        System.out.println("s: " + s);
        System.out.println("Resolvable? " + s.isResolvable() + " Steps simplifying: " + s.getStepsForSimplifying() + " Steps resolving: " + s.getStepsForResolving());
        System.out.println("----------------------");
        s = SAT.parse("0 a\n-a b\n-a b\n-a b\n-a b\na -a c d e");
        System.out.println("s: " + s);
        System.out.println("Resolvable? " + s.isResolvable() + " Steps simplifying: " + s.getStepsForSimplifying() + " Steps resolving: " + s.getStepsForResolving());
        s.resetCounters();
        s.simplifyClauses();
        System.out.println("Simplified. Steps simplifying: " + s.getStepsForSimplifying());
        s.resetCounters();
        System.out.println("s: " + s);
        System.out.println("Resolvable? " + s.isResolvable() + " Steps simplifying: " + s.getStepsForSimplifying() + " Steps resolving: " + s.getStepsForResolving());
        System.out.println("----------------------");
        s = SAT.parse("-a b\na");
        System.out.println("s: " + s);
        System.out.println("Resolvable? " + s.isResolvable() + " Steps simplifying: " + s.getStepsForSimplifying() + " Steps resolving: " + s.getStepsForResolving());
        s.resetCounters();
        s.simplifyClauses();
        System.out.println("Simplified. Steps simplifying: " + s.getStepsForSimplifying());
        s.resetCounters();
        System.out.println("s: " + s);
        System.out.println("Resolvable? " + s.isResolvable() + " Steps simplifying: " + s.getStepsForSimplifying() + " Steps resolving: " + s.getStepsForResolving());
        System.out.println("----------------------");
        s = SAT.parse("0\n-a b\na");
        System.out.println("s: " + s);
        System.out.println("Resolvable? " + s.isResolvable() + " Steps simplifying: " + s.getStepsForSimplifying() + " Steps resolving: " + s.getStepsForResolving());
        s.resetCounters();
        s.simplifyClauses();
        System.out.println("Simplified. Steps simplifying: " + s.getStepsForSimplifying());
        s.resetCounters();
        System.out.println("s: " + s);
        System.out.println("Resolvable? " + s.isResolvable() + " Steps simplifying: " + s.getStepsForSimplifying() + " Steps resolving: " + s.getStepsForResolving());
        System.out.println("----------------------");
        s = SAT.parse("a b -c");
        System.out.println("s: " + s);
        System.out.println("Resolvable? " + s.isResolvable() + " Steps simplifying: " + s.getStepsForSimplifying() + " Steps resolving: " + s.getStepsForResolving());
        s.resetCounters();
        s.simplifyClauses();
        System.out.println("Simplified. Steps simplifying: " + s.getStepsForSimplifying());
        s.resetCounters();
        System.out.println("s: " + s);
        System.out.println("Resolvable? " + s.isResolvable() + " Steps simplifying: " + s.getStepsForSimplifying() + " Steps resolving: " + s.getStepsForResolving());

        /*
        System.out.println("----------------------");
        s = SAT.parse("a c\nb c\n-c");
        System.out.println(s.isResolvable());
        System.out.println(s.clauses);
        System.out.println(s);
        s.simplifyClauses();
        System.out.println(s.isResolvable());
        System.out.println(s);
        System.out.println("----------------------");
        s = SAT.parse("c\n-c");
        System.out.println(s.isResolvable());
        System.out.println(s.clauses);
        System.out.println(s);
        s.simplifyClauses();
        System.out.println(s.isResolvable());
        System.out.println(s);
         */
    }
}
