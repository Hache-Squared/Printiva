namespace ManejoPresupuestos.Models
{
    public class ReporteOpcionRow
    {
        public int Id { get; set; }
        public string Nombre { get; set; } = "";
    }

    public class ReportePedidoOperativoRow
    {
        public int PedidoId { get; set; }

        public int ClienteId { get; set; }
        public string ClienteNombre { get; set; } = "";

        public decimal Total { get; set; }
        public decimal TotalPagado { get; set; }
        public decimal Saldo { get; set; }
        public decimal PagadoPorcentaje { get; set; }

        public int PedidoEstatusId { get; set; }
        public string PedidoEstatusNombre { get; set; } = "";

        public int ProduccionItems { get; set; }
        public int? ProduccionEstatusId { get; set; }
        public string? ProduccionEstatusNombre { get; set; }

        public DateTime FechaCreacion { get; set; }
        public DateTime? FechaEntregaEstimada { get; set; }

        public bool EsAtrasado { get; set; }
        public int DiasAtraso { get; set; }

        public int Prioridad { get; set; }
    }

    public class ReportePedidosOperativosViewModel
    {
        // Filtros
        public DateTime Desde { get; set; }
        public DateTime Hasta { get; set; }

        public int? PedidoEstatusId { get; set; }
        public int? ClienteId { get; set; }
        public bool SoloAtrasados { get; set; }

        public int? ProduccionEstatusId { get; set; }
        public string? Canal { get; set; }

        // Lookups
        public List<ReporteOpcionRow> EstatusPedido { get; set; } = new();
        public List<ReporteOpcionRow> EstatusProduccion { get; set; } = new();
        public List<ReporteOpcionRow> Clientes { get; set; } = new();

        // Data
        public List<ReportePedidoOperativoRow> Rows { get; set; } = new();

        // KPIs simples
        public int TotalPedidos => Rows.Count;
        public int TotalAtrasados => Rows.Count(x => x.EsAtrasado);
        public decimal TotalSaldo => Rows.Sum(x => x.Saldo);
    }
}