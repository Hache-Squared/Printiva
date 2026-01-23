using Microsoft.AspNetCore.Mvc.Rendering;

namespace ManejoPresupuestos.Models
{
    public class PedidoKanbanCard
    {
        public int PedidoId { get; set; }
        public int ClienteId { get; set; }
        public string ClienteNombre { get; set; } = "";
        public int PedidoEstatusId { get; set; }
        public string EstatusNombre { get; set; } = "";
        public DateTime FechaCreacion { get; set; }
        public DateTime? FechaEntregaEstimada { get; set; }
        public decimal? TotalEstimado { get; set; }
        public string? Notas { get; set; }

        public int CotizacionId { get; set; }
        public string CotizacionEstatusNombre { get; set; } = "";
        public bool TieneCotizacion { get; set; }
        public bool CotizacionAceptada { get; set; }
        public decimal TotalCotizado { get; set; }
        public decimal TotalPagado { get; set; }
        public decimal Saldo { get; set; }
    }

    public class PedidoKanbanViewModel
    {
        public IEnumerable<SelectListItem> Clientes { get; set; } = Enumerable.Empty<SelectListItem>();
        public IEnumerable<PedidoEstatusRow> Estatus { get; set; } = Enumerable.Empty<PedidoEstatusRow>();
    }

    public class PedidoEstatusRow
    {
        public int PedidoEstatusId { get; set; }
        public string Nombre { get; set; } = "";
    }
}
