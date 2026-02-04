namespace ManejoPresupuestos.Models
{
    public class CatalogoDto
    {
        public int Id { get; set; }
        public string Nombre { get; set; } = "";
    }

    public class ReporteComprasHistoricoKpiDto
    {
        public int Compras { get; set; }
        public int ComprasInventario { get; set; }
        public int ComprasNoInventario { get; set; }

        public decimal GastoTotal { get; set; }          // money
        public decimal GastoInventario { get; set; }     // money
        public decimal GastoNoInventario { get; set; }   // money

        public decimal CantidadTotalInventario { get; set; } // qty
    }

    public class ReporteComprasTopCategoriaDto
    {
        public int CategoriaId { get; set; }
        public string CategoriaNombre { get; set; } = "";
        public int Compras { get; set; }
        public decimal Total { get; set; } // money
    }

    public class ReporteComprasTopTipoDto
    {
        public int TipoId { get; set; }
        public string TipoNombre { get; set; } = "";
        public int EsInventario { get; set; } // 0/1
        public int Compras { get; set; }
        public decimal Total { get; set; } // money
    }

    public class ReporteComprasTopInventarioDto
    {
        public int InventarioId { get; set; }
        public string InventarioNombre { get; set; } = "";
        public string? UnidadNombre { get; set; }
        public int Compras { get; set; }
        public decimal Cantidad { get; set; } // qty
        public decimal Total { get; set; }    // money
    }

    public class ReporteComprasHistoricoDetalleDto
    {
        public int CompraId { get; set; }
        public DateTime FechaCompraFinal { get; set; }
        public DateTime FechaLogFinal { get; set; }

        public int CompraCategoriaId { get; set; }
        public string CategoriaNombre { get; set; } = "";

        public int CompraTipoId { get; set; }
        public string TipoNombre { get; set; } = "";
        public bool EsInventario { get; set; }
        public bool AfectoInventario { get; set; }

        public string? CompraDescripcion { get; set; }

        public int? FilamentoTipoId { get; set; }
        public string? FilamentoTipoNombre { get; set; }

        public int? InventarioId { get; set; }
        public string? InventarioNombre { get; set; }
        public string? InventarioUnidadNombre { get; set; }

        public decimal CantidadFinal { get; set; }       // qty
        public decimal CostoUnitarioFinal { get; set; }  // money
        public decimal CostoTotalFinal { get; set; }     // money

        public decimal? InventarioCantidadActual { get; set; } // qty
        public decimal? InventarioAntes { get; set; }          // qty
        public decimal? InventarioDespues { get; set; }        // qty

        public string? Operacion { get; set; }
        public string? TransaccionDescripcion { get; set; }
        public bool EstaActivo { get; set; }
    }

    public class ReporteComprasHistoricoVm
    {
        // filtros
        public DateTime? Desde { get; set; }
        public DateTime? Hasta { get; set; }

        public int? CompraId { get; set; }
        public int? CategoriaId { get; set; }
        public int? TipoId { get; set; }
        public int? InventarioId { get; set; }

        public bool? SoloActivos { get; set; }
        public bool? SoloInventario { get; set; }

        public int TopN { get; set; } = 10;
        public string? Q { get; set; }

        // data
        public ReporteComprasHistoricoKpiDto Kpis { get; set; } = new();
        public List<ReporteComprasTopCategoriaDto> TopCategorias { get; set; } = new();
        public List<ReporteComprasTopTipoDto> TopTipos { get; set; } = new();
        public List<ReporteComprasTopInventarioDto> TopInventarios { get; set; } = new();
        public List<ReporteComprasHistoricoDetalleDto> Detalle { get; set; } = new();

        // catálogos
        public List<CatalogoDto> Categorias { get; set; } = new();
        public List<CatalogoDto> Tipos { get; set; } = new();
        public List<CatalogoDto> Inventarios { get; set; } = new();
    }
}