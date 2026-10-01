class_name SaveV2DiagnosticSandbox
extends RefCounted

## Bloco C6 — contrato do alvo DIAGNÓSTICO de um load V2.
##
## Cada experiência fornece uma implementação (Vardhelm: VardhelmDiagnosticSandbox)
## que cria um runtime ISOLADO e descartável. O coordenador só conhece este
## contrato: não sabe criar cenas, não conhece nós nem o jogo principal.
##
##   create_targets() -> RuntimeRestoreTargets de um runtime NOVO (is_sandbox = true)
##   discard()        -> destrói esse runtime; depois disso nada dele é usado
##
## A implementação padrão (esta) não cria nada: create_targets() devolve null e o
## coordenador rejeita a restauração.


func create_targets() -> RuntimeRestoreTargets:
	return null


func discard() -> void:
	pass


func is_discarded() -> bool:
	return true


## C7: um sandbox NOVO do mesmo tipo (o Load V2 operacional precisa de dois:
## rehearsal do arquivo e rehearsal do snapshot). null = não suportado.
func spawn() -> SaveV2DiagnosticSandbox:
	return null
