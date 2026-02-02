using System;

namespace ManejoPresupuestos.Models
{
    public class TarifaHistoricoDto
    {
        public int TarifaLogId { get; set; }
        public string Accion { get; set; } = "";

        public int? ImpresoraId { get; set; }
        public int? InventarioId { get; set; }

        public string? NombreAntes { get; set; }
        public string? NombreDespues { get; set; }

        public int? OrdenAntes { get; set; }
        public int? OrdenDespues { get; set; }

        public decimal? MontoAntes { get; set; }
        public string? MonedaAntes { get; set; }

        public decimal? MontoDespues { get; set; }
        public string? MonedaDespues { get; set; }

        public bool? EstaActivoAntes { get; set; }
        public bool? EstaActivoDespues { get; set; }

        public DateTime FechaAccion { get; set; }
    }
}