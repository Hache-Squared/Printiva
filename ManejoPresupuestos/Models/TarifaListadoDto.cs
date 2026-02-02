using System;

namespace ManejoPresupuestos.Models
{
    public class TarifaListadoDto
    {
        public int TarifaId { get; set; }

        public string TarifaNombre { get; set; } = "";
        public int TarifaOrden { get; set; }

        public string ConceptoCodigo { get; set; } = "";
        public string ConceptoNombre { get; set; } = "";
        public string Unidad { get; set; } = "";

        public int? ImpresoraId { get; set; }
        public int? InventarioId { get; set; }

        public decimal Monto { get; set; }
        public string Moneda { get; set; } = "MXN";

        public DateTime FechaUltimoCambio { get; set; }
    }
}