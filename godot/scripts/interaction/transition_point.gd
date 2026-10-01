class_name TransitionPoint
extends Interactable

## C21 — ponto de passagem entre duas áreas (ex.: a talha que liga o patamar da Forja 01
## ao pátio das fundições). Mesmo contrato do Interactable: camada 2, detector, prioridade
## e tecla E não mudam. Aqui ficam só os dados da passagem; quem a executa (fade, mover o
## jogador) é o controlador da área, ligado em interaction_requested.
##
## Estado transitório: nada disto é salvo. Depois de um Load, a posição do jogador (Save V2)
## já diz em que área ele está.

## Chave de localização do texto da dica ("E • <texto>").
@export var prompt_key: String = ""
## Onde o jogador chega do outro lado (coordenadas de mundo).
@export var destination: Vector3 = Vector3.ZERO
## Identificador do outro lado da passagem (ex.: "hoist_bottom").
@export var destination_id: String = ""
