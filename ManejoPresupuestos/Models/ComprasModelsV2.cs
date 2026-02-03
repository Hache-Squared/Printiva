// File: Models/ComprasModelsV2.cs
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace ManejoPresupuestos.Models
{
    public enum SubMenuCompras
    {
        Compras = 1,
        Categorias = 2,
        Tipos = 3,
        Filamentos = 4
    }

    // Resultado estándar de SPs tipo "procAltera..."
    public class SpResult
    {
        public string Result { get; set; } = string.Empty;   // "success" | "fail"
        public string Message { get; set; } = string.Empty;
        public int ElementoId { get; set; }
    }

    // =========================
    // ENTIDAD / DTO PRINCIPAL
    // =========================
    public class CompraV2
    {
        public int CompraId { get; set; }

        [Required(ErrorMessage = "El campo {0} es obligatorio")]
        [Display(Name = "Descripción")]
        public string Descripcion { get; set; } = string.Empty;

        [Display(Name = "Tipo de compra")]
        [Range(1, int.MaxValue, ErrorMessage = "Selecciona un {0}")]
        public int CompraTipoId { get; set; }

        [Display(Name = "Categoría de compra")]
        [Range(1, int.MaxValue, ErrorMessage = "Selecciona una {0}")]
        public int CompraCategoriaId { get; set; }

        [Display(Name = "Tipo de filamento")]
        public int? FilamentoTipoId { get; set; }

        // V2: integra inventario (si aplica)
        [Display(Name = "Inventario")]
        public int? InventarioId { get; set; }

        [Display(Name = "Cantidad")]
        public decimal Cantidad { get; set; } = 0;

        [Display(Name = "Costo unitario")]
        public decimal CostoUnitario { get; set; } = 0;

        [Display(Name = "Costo total")]
        public decimal CostoTotal { get; set; } = 0;

        [Display(Name = "Fecha")]
        [DataType(DataType.Date)]
        public DateTime FechaCreacion { get; set; } = DateTime.Today;

        // Borrado lógico
        public bool EstaActivo { get; set; } = true;

        // Campos "lookup" para listados
        public string CompraTipo { get; set; } = string.Empty;
        public bool EsInventario { get; set; } = false;
        public bool RequiereFilamentoTipo { get; set; } = false;

        public string CompraCategoria { get; set; } = string.Empty;
        public string? FilamentoTipo { get; set; } = string.Empty;

        public string? InventarioNombre { get; set; } = string.Empty;
        public string? InventarioNombreAbreviatura { get; set; } = string.Empty;
        public string? InventarioColor { get; set; } = string.Empty;
        public string? InventarioColorAbreviatura { get; set; } = string.Empty;
        public string? InventarioUnidad { get; set; } = string.Empty;
    }

    // =========================
    // CATÁLOGOS (V2)
    // =========================
    public class CompraCategoriaV2
    {
        public int CompraCategoriaId { get; set; }

        [Required(ErrorMessage = "El campo {0} es obligatorio")]
        [StringLength(200)]
        public string Nombre { get; set; } = string.Empty;

        public bool EstaActivo { get; set; } = true;
    }

     public class CompraTipoV2
    {
        public int CompraTipoId { get; set; }

        [Required(ErrorMessage = "Nombre es requerido.")]
        [StringLength(200, ErrorMessage = "Máximo 200 caracteres.")]
        public string Nombre { get; set; } = string.Empty;

        // Si este tipo afecta inventario (Filamento/Herramienta/Material/etc)
        public bool EsInventario { get; set; }

        // Borrado lógico
        public bool EstaActivo { get; set; } = true;
    }

    // Tu entidad ya existía en V1; la reuso aquí para no romper
    public class FilamentoTipo
    {
        public int FilamentoTipoId { get; set; }
        public string Nombre { get; set; } = string.Empty;
    }

    // =========================
    // VIEWMODEL FORMULARIO
    // =========================
    
    public class CompraV2FormViewModel
    {
        public int CompraId { get; set; }

        [Required(ErrorMessage = "El campo {0} es obligatorio")]
        [Display(Name = "Descripción")]
        public string Descripcion { get; set; } = string.Empty;

        [Display(Name = "Tipo de compra")]
        [Range(1, int.MaxValue, ErrorMessage = "Selecciona un {0}")]
        public int CompraTipoId { get; set; }

        [Display(Name = "Categoría de compra")]
        [Range(1, int.MaxValue, ErrorMessage = "Selecciona una {0}")]
        public int CompraCategoriaId { get; set; }

        // Inventario (si aplica)
        [Display(Name = "Inventario")]
        public int? InventarioId { get; set; }

        [Display(Name = "Cantidad")]
        public decimal Cantidad { get; set; } = 0;

        [Display(Name = "Costo unitario")]
        public decimal CostoUnitario { get; set; } = 0;

        [Display(Name = "Costo total")]
        public decimal CostoTotal { get; set; } = 0;

        [Display(Name = "Fecha")]
        [DataType(DataType.Date)]
        public DateTime FechaCreacion { get; set; } = DateTime.Today;

        // Selects
        public IEnumerable<SelectListItem> Tipos { get; set; } = Enumerable.Empty<SelectListItem>();
        public IEnumerable<SelectListItem> Categorias { get; set; } = Enumerable.Empty<SelectListItem>();
        public IEnumerable<SelectListItem> Inventarios { get; set; } = Enumerable.Empty<SelectListItem>();
    }
}