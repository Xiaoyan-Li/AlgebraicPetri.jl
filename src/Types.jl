module Types
export TheoryPetri, Petri, AbstractPetri, ns, nt, ni, no,
  add_species!, add_transition!, add_transitions!,
  add_input!, add_inputs!, add_output!, add_outputs!, inputs, outputs,
  TheoryReactionNet, ReactionNet, AbstractReactionNet

using Catlab
using Catlab.CategoricalAlgebra.CSets
using Catlab.Present
using Catlab.Theories

# Petri Nets
############

@present TheoryPetri(FreeCategory) begin
  T::Ob
  S::Ob
  I::Ob
  O::Ob

  it::Hom(I,T)
  is::Hom(I,S)
  ot::Hom(O,T)
  os::Hom(O,S)
end

const AbstractPetri = AbstractCSetType(TheoryPetri)
const Petri = CSetType(TheoryPetri, index=[:is,:it,:os,:ot])

ns(p::AbstractPetri) = nparts(p,:S)
nt(p::AbstractPetri) = nparts(p,:T)
ni(p::AbstractPetri) = nparts(p,:I)
no(p::AbstractPetri) = nparts(p,:O)

add_species!(p::AbstractPetri) = add_part!(p,:S)
add_species!(p::AbstractPetri,n) = add_parts!(p,:S,n)

add_transition!(p::AbstractPetri) = add_part!(p,:T)
add_transitions!(p::AbstractPetri,n) = add_parts!(p,:T,n)

add_input!(p::AbstractPetri,t,s) = add_part!(p,:I,(is=s,it=t))
add_inputs!(p::AbstractPetri,n,t,s) = add_parts!(p,:I,n,(is=s,it=t))

add_output!(p::AbstractPetri,t,s) = add_part!(p,:O,(os=s,ot=t))
add_output!(p::AbstractPetri,n,t,s) = add_parts!(p,:O,n,(os=s,ot=t))

# Note: although indexing makes this pretty fast, it is often faster to bulk-convert
# the Petri net into a transition matrix, if you are working with all of the transitions
inputs(p::AbstractPetri,t) = subpart(p,incident(p,t,:it),:is)
outputs(p::AbstractPetri,t) = subpart(p,incident(p,t,:ot),:os)

struct TransitionMatrices
  input::Matrix{Int}
  output::Matrix{Int}
  TransitionMatrices(p::AbstractPetri) = begin
    input, output = zeros(Int,(nt(p),ns(p))), zeros(Int,(nt(p),ns(p)))
    for i in 1:ni(p)
      input[subpart(p,i,:it),subpart(p,i,:is)] += 1
    end
    for i in 1:no(p)
      output[subpart(p,i,:ot),subpart(p,o,:os)] += 1
    end
    new(input,output)
  end
end

Petri(tm::TransitionMatrices) =
  (m,n) = size(tm.input)
  p = Petri()
  add_species!(p,n)
  add_transitions!(p,m)
  for i in 1:m
    for j in 1:n
      add_inputs!(p,tm.input[i,j],i,j)
      add_outputs!(p,tm.output[i,j],i,j)
    end
  end
  p
end

rate_eq(p::AbstractPetri) = begin
  tm = TransitionMatrices(p)
  f(du,u,p,t) = begin
    log_rates = log.(p) .+ tm.input * log.(u)
    du = (tm.output - tm.input) * exp.(log_rates)
  end
  f
end

# Reaction Nets
###############

@present TheoryReactionNet <: TheoryPetri begin
  number::Ob

  rate::Hom(T, number)
  u0::Hom(S, number)
end

const AbstractReactionNet = AbstractCSetType(TheoryReactionNet, data=[:number])
const ReactionNet = CSetType(TheoryReactionNet, index=[:is,:it,:os,:ot], data=[:number])

end
