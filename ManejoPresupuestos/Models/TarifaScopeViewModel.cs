using System.Collections.Generic;

namespace ManejoPresupuestos.Models
{
    public class TarifaScopeViewModel
    {
        public TarifaScopeType ScopeType { get; set; }
        public int ScopeId { get; set; }

        // Para el titulo (si no tienes nombre, minimo muestra #id)
        public string ScopeTitulo { get; set; } = "";

        public List<TarifaConceptoDto> Conceptos { get; set; } = new();
        public List<TarifaListadoDto> Tarifas { get; set; } = new();
    }
}