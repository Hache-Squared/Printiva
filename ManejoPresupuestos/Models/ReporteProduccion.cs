using System;
using System.Collections.Generic;

namespace ManejoPresupuestos.Models
{
    public class ReporteProduccionWipTotales
    {
        public int Items { get; set; }
        public int WipItems { get; set; }
        public int FinalizadosItems { get; set; }
        public int SinImpresora { get; set; }
        public int Atrasados { get; set; }

        public int CantidadTotal { get; set; }

        public decimal PesoEstimadoTotalGr { get; set; }
        public decimal PesoRealTotalGr { get; set; }

        public decimal AvgDiasEnEstatus { get; set; }
        public int MaxDiasEnEstatus { get; set; }
    }

    public class ReporteProduccionWipEstatusAgg
    {
        public int ProduccionEstatusId { get; set; }
        public string? ProduccionEstatusNombre { get; set; }
        public int ProduccionEstatusOrden { get; set; }
        public string? BadgeClass { get; set; }

        public int Items { get; set; }
        public int Cantidad { get; set; }

        public decimal PesoEstimadoTotalGr { get; set; }
        public decimal PesoRealTotalGr { get; set; }

        public int Atrasados { get; set; }

        public decimal AvgDiasEnEstatus { get; set; }
        public int MaxDiasEnEstatus { get; set; }
    }

    public class ReporteProduccionWipImpresoraAgg
    {
        public int? ImpresoraId { get; set; }
        public string? ImpresoraNombre { get; set; }
        public string? ImpresoraModelo { get; set; }

        public int Items { get; set; }
        public int Cantidad { get; set; }

        public int WipItems { get; set; }
        public int Atrasados { get; set; }

        public decimal AvgDiasEnEstatus { get; set; }
        public int MaxDiasEnEstatus { get; set; }
    }

    public class ReporteProduccionWipColaBucketAgg
    {
        public int ColaBucketId { get; set; }
        public string? ColaBucketNombre { get; set; }

        public int Items { get; set; }
        public int Cantidad { get; set; }

        public int Atrasados { get; set; }

        public decimal AvgDiasEnEstatus { get; set; }
        public int MaxDiasEnEstatus { get; set; }
    }

    public class ReporteProduccionWipDetalleRow
    {
        public int ProduccionItemId { get; set; }
        public int PedidoId { get; set; }
        public int PedidoItemId { get; set; }

        public int ClienteId { get; set; }
        public string? ClienteNombre { get; set; }

        public int ProductoId { get; set; }
        public string? ProductoNombre { get; set; }

        public int Cantidad { get; set; }

        public int ProduccionEstatusId { get; set; }
        public string? ProduccionEstatusNombre { get; set; }
        public int ProduccionEstatusOrden { get; set; }
        public string? BadgeClass { get; set; }

        public int? ImpresoraId { get; set; }
        public string? ImpresoraNombre { get; set; }
        public string? ImpresoraModelo { get; set; }

        public int? RecetaId { get; set; }
        public string? RecetaNombre { get; set; }

        public DateTime FechaCreacion { get; set; }
        public DateTime FechaEnEstatus { get; set; }
        public int DiasEnEstatus { get; set; }

        public DateTime? FechaInicio { get; set; }
        public DateTime? FechaFin { get; set; }
        public DateTime? FechaEntregaEstimada { get; set; }

        public bool EsWip { get; set; }
        public bool Atrasado { get; set; }

        public int ColaBucketId { get; set; }
        public string? ColaBucketNombre { get; set; }

        public decimal? PesoEstimadoGr { get; set; }
        public decimal? PesoRealGr { get; set; }

        public bool InventarioAplicado { get; set; }
        public string? Notas { get; set; }
        public string? NotasOperativas { get; set; }
    }

    // Catálogos (dropdowns)
    public class ReporteCatalogEstatusRow
    {
        public int Id { get; set; }
        public string? Nombre { get; set; }
        public int Orden { get; set; }
        public string? BadgeClass { get; set; }
    }

    public class ReporteCatalogImpresoraRow
    {
        public int Id { get; set; }
        public string? Nombre { get; set; }
        public string? Modelo { get; set; }
    }

    public class ReporteCatalogClienteRow
    {
        public int Id { get; set; }
        public string? Nombre { get; set; }
    }

    public class ReporteProduccionWipViewModel
    {
        // filtros (GET)
        public DateTime? Desde { get; set; }
        public DateTime? Hasta { get; set; }
        public int? ClienteId { get; set; }
        public int? PedidoId { get; set; }
        public int? EstatusId { get; set; }
        public int? ImpresoraId { get; set; }

        public bool SoloWip { get; set; }
        public bool SoloAtrasados { get; set; }
        public bool SinImpresora { get; set; }

        public int? MinDiasCola { get; set; }
        public string? Q { get; set; }

        // resultado
        public ReporteProduccionWipTotales Totales { get; set; } = new();

        public List<ReporteProduccionWipEstatusAgg> WipPorEstatus { get; set; } = new();
        public List<ReporteProduccionWipImpresoraAgg> PorImpresora { get; set; } = new();
        public List<ReporteProduccionWipColaBucketAgg> PorAntiguedad { get; set; } = new();
        public List<ReporteProduccionWipDetalleRow> Detalle { get; set; } = new();

        // catálogos
        public List<ReporteCatalogEstatusRow> CatEstatus { get; set; } = new();
        public List<ReporteCatalogImpresoraRow> CatImpresoras { get; set; } = new();
        public List<ReporteCatalogClienteRow> CatClientes { get; set; } = new();
    }
}